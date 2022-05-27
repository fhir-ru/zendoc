(ns zd.zen
  (:require [stylo.core :refer [c c?]]
            [clj-yaml.core]
            [zen.core]
            [clojure.string :as str]
            [clojure.edn]
            [clojure.walk]))

(defn cls [cs]
  (str/join " " (map name cs)))

(defn contains-name? [confirms x]
  (when confirms
    (contains? (into #{} (map name confirms)) x)))

(defn type-icon [tp confirms extension]
  [:div {:class (cls
                 (cond-> 
                     [(c [:w 4] [:h 4]
                         :text-xs
                         :flex
                         :items-center
                         :justify-center
                         :shadow
                         [:text :gray-700]
                         {:border-radius "4px"
                          :border "1px solid #ccc"
                          :font-size "9px"})]
                   extension (conj (c [:bg :green-200]))
                   (not extension) (conj (c [:bg :gray-300]))
                   ))}
   (cond
     (contains-name? confirms "Coding") [:div.fa-solid.fa-tag]
     (contains-name? confirms "CodeableConcept") [:div.fa-solid.fa-tags]
     (contains-name? confirms "Reference") [:div.fa-solid.fa-arrow-up-right-from-square]
     (nil? tp) [:div " "]
     (= tp 'zen/set) [:div "#{ }"]
     (= tp 'zen/map) [:div "{ }"]
     (= tp 'zen/case) [:div "?"]
     (= tp 'zen/vector) [:div "[ ]"]
     (= tp 'zen/date) [:div.fa.fa-calendar-day]
     (= tp 'zen/datetime) [:div.fa.fa-calendar-day]
     (= tp 'zen/boolean) [:div.fa.fa-toggle-on]
     (= tp 'zen/string) [:div.fa.fa-pencil {:class (cls [(c {:line-height "inherit!important"})])}]
     (= tp 'zen/integer) [:b "1"]
     :else (first (last (str/split (str tp) #"/"))))])

(defn flatten-sch [res pth {tp :type :as sch} & [opts ztx]]
  (let [res (if (:skip opts)
              res
              (conj res (merge opts {:type tp
                                     :confirms (if (= 'zen/vector tp)
                                                 (get-in sch [:every :confirms])
                                                 (:confirms sch))
                                     :extension (:fhir/extensionUri sch)
                                     :cardinality (format "%s..%s"
                                                          (cond (:require opts) "1"
                                                                (:minItems opts) (:minItems opts)
                                                                :else "0")
                                                          (cond
                                                            (= 'zen/vector tp) "*"
                                                            (:maxItems opts) (:maxItems opts)
                                                            :else "1"))
                                     :path pth
                                     :enum (:enum sch)
                                     :valueset (:valueset sch)
                                     :desc (:zen/desc sch)})))]
    (cond
      
      (= tp 'zen/map)
      (let [ks (->> (if (:match opts)
                      (select-keys 
                       (:keys sch)
                       (keys (:match opts)))
                      (:keys sch))
                    (sort-by (fn [[_ v]] (:row (meta v)))))]
        (loop [[[k v] & ks] ks
               res res]
          (if (nil? k)
            res
            (recur ks
             (flatten-sch res
                          (conj pth {:key k :last (empty? ks)}) v
                          {:require (contains? (:require sch) k)
                           :const   (get-in opts [:match k])}
                          ztx)))))
      (= tp 'zen/vector)
      (cond
        (get-in sch [:every :keys])
        (flatten-sch res
                     pth
                     (:every sch)
                     {:skip true}
                     ztx)

        (:slicing sch)
        (let [confirm-schema (zen.core/get-symbol ztx (-> sch :every :confirms first))]
          (loop [slices (-> sch :slicing :slices seq) acc res]
            (if (seq slices)
              (let [[slice-name slice-data] (first slices)]
                (recur (rest slices)
                       (flatten-sch acc
                                    (conj pth {:key slice-name :last (empty? (rest slices))})
                                    (assoc (merge confirm-schema
                                                  (:every (:schema slice-data))) 
                                           :zen/desc (-> slice-data :zen/desc)
                                           :confirms (:confirms (:every sch)))
                                    {:match (merge (->> (-> slice-data :schema :every :require)
                                                        (mapv (fn [v] [v nil]))
                                                        (into {}))
                                                   (-> slice-data :filter :match))
                                     :minItems (-> slice-data :schema :minItems)
                                     :maxItems (-> slice-data :schema :maxItems)}
                                    ztx)))
              acc)))
        :else res)
      
      :else res)))

(defn schema-name [sym]
  (when (and sym (not (= sym 'zen/map)))
    (if (= "schema" (name sym))
      (last (str/split (namespace sym) #"\."))
      (name sym))
    #_(str 
     (->> (str/split (namespace sym) #"\.")
          (mapv first)
          (str/join "."))
     "/" (name sym))))

(defn schema-connectors [pth]
  (let [lvl (count pth)
        scale 1]
    [:div {:class (c :flex [:py 1] [:px 1] :items-center {:position "relative" :height "100%"})
           :style (str "padding-left:" (* scale (+ lvl 0.5)) "rem")}
     (->> pth
          (map-indexed
           (fn [i {lst? :last}]
             (if lst?
               (when (= i (dec lvl))
                 [:div {:style (str "left:" (* scale (+ i 1)) "rem")
                        :class (c [:w 2] {:border-left "1px solid #ccc"
                                          :position "absolute"
                                          :top "-0.3rem"
                                          :height "18px"})}])
               [:div {:style (str "left:" (* scale (+ i 1)) "rem")
                      :class (c [:w 2] {:border-left "1px solid #ccc"
                                        :position "absolute"
                                        :top "-0.3rem"
                                        :bottom 0})}]))))
     (when-not (= lvl 0)
       [:div {:style (str "left:" (* scale lvl) "rem")
              :class (c {:border-top "1px solid #ccc"
                         :position "absolute"
                         :width "0.5rem"
                         :top "13px"})}])]))


(defn deep-merge
  "efficient deep merge"
  [a b]
  (loop [[[k v :as i] & ks] b
         acc a]
    (if (nil? i)
      acc
      (let [av (get a k)]
        (if (= v av)
          (recur ks acc)
          (recur ks
                 (cond
                   (and (map? v) (map? av)) (assoc acc k (deep-merge av v))
                   (and (nil? v) (map? av)) (assoc acc k av)
                   :else (assoc acc k v))))))))


;; sch(confirms) -> sch(confirms) -> sch

(defn clear-primitives [sch]
  (cond
    (:every sch)
    (update sch :every clear-primitives)

    (:keys sch)
    (update sch :keys (fn [ks]
                        (->> ks
                             (reduce (fn [acc [k v]]
                                       (if (str/starts-with? (name k) "_")
                                         acc
                                         (assoc acc k (clear-primitives v)))) {}))))
    :else sch))

(defn effective-schema [ztx sch-name]
  (let [sch   (zen.core/get-symbol ztx sch-name)
        sch (->> (:confirms sch)
                    (reduce
                     (fn [acc nm]
                       (deep-merge (effective-schema ztx nm) acc)
                       ) sch))]
    (clear-primitives sch)))

(defn schema-table [sch & [ztx]]
  [:table.schema
   [:tbody
    [:tr {:class (c [:text :gray-700] :text-left)}
     (let [th-style (c :font-medium)]
       (list [:th {:class th-style} "Название"]
             [:th {:class th-style} "Кол-во"]
             [:th {:class th-style} "Тип"]
             [:th {:class th-style} "Описание"]))]
    (for [{pth :path :as row} (flatten-sch [] [] sch {:name (:zen/name sch)} ztx)]
      [:tr
       [:td {:class (c :text-sm)} 
        (into (schema-connectors pth)
              [(type-icon (:type row) (:confirms row) (:extension row))
               [:div {:class (c [:ml 3])}
                (if-let [nm (:name row)]
                  (schema-name nm)
                  (when-let [k (:key (last (:path row)))] (name k)))]])]
       [:td {:class (c :text-sm [:px 3])}
        (:cardinality row)]
       [:td {:class (c [:text :blue-600] :text-sm [:px 3])}
        (if (:confirms row)
          (str/join ", " (mapv schema-name (:confirms row)))
          (when-let [t (:type row)] (schema-name t)))]
       [:td {:class (c [:text :gray-700] :text-xs )}
        (when-let [d (:desc row)]
          [:div {:class (c :text-xs [:text :gray-700])} d])
        (when-let [d (:const row)]
          [:div {:class (c :text-xs [:text :gray-700])}
           [:b "Fixed value: "]
           [:span {:class (c [:text :green-700])}
            d]])
        (when-let [vs (:valueset row)]
          (str "vs:" (:id vs)))
        (when-let [vs (:extension row)]
          (str "ext:" vs))
        (when-let [enum (:enum row)]
          [:div {:class (c :flex :items-baseline [:space-x 1] :text-xs)}
           [:b "enum:" ]
           (for [{v :value} enum]
             [:span v ";"])])]])]])

(def style
  [:style
   "
table.schema {width: 100%;}
table.schema tr:nth-child(even) {background: rgba(247,250,252,var(--bg-opacity));}
table.schema td {}
.zd-tabs .active { border-bottom: 2px solid #888; font-weight: 500;}

.tabs {
  display: flex;
  flex-wrap: wrap;
}
.tabs .tabe {
  order: 99;
  flex-grow: 1;
  width: 100%;
  display: none;
}
.tabs input[type=\"radio\"] {
  display: none;
}

.tabs input[type=\"radio\"]:checked + .tabh {
  border-bottom: 2px solid #888;
  font-weight: 500;
}

.tabs input[type=\"radio\"]:checked + .tabh + .tabe {
  display: block;
}
"])

(def tab-cls
  (c [:px 2] :cursor-pointer {:margin-bottom "-1px" :border-bottom "2px solid transparent"}
     [:hover [:bg :gray-100]])
  )

(defn zen-message-view
  [schema-name message]
  [:div {:class (c [:bg :red-200] :border [:p 2] [:my 2] :text-xs)}
   [:div {:class (c :font-bold)}
    (->> (:path message)
         (map #(if (keyword? %) (name %) %))
         (interpose ".")
         (apply str)
         (str schema-name "."))]
   (:message message)])

(defn validation-tab
  [ztx schema-name http-params]
  (let [data
        (some->
         (get http-params "data")
         (clj-yaml.core/parse-string))
        data-errors
        (when data
          (zen.core/validate ztx #{schema-name} data))]
    [:div
     [:form {:id "form-validate" :action "" :method "POST"}
      [:input {:class (c :hidden) :name "form-type" :value "validation"}]
      [:textarea {:name "data" :class (c [:my 2] :w-full :border) :rows 20}
       (get http-params "data")]
      [:button
       {:onclick "on_form_validate()"
        :class   (c [:my 2] [:p 2] [:bg :gray-100] :shadow-sm :border)}
       "Check"]]
     (if-let [errors (seq (:errors data-errors))]
       (for [error errors]
         (zen-message-view schema-name error))
       [:div {:class (c [:text :green-500])}
        [:ul {:class "fa-ul"}
         [:li {:class (c :list-none)}
          [:span {:class "fa-li"} [:i {:class ["fa-solid" "fa-check-square"]}]]
          "Ресурс прошел валидацию."]]])]))

(defn get-profile-schema-errors
  [ztx schema-name]
  (->> (zen.core/errors ztx)
       (filter
        (fn [error]
          (or (= schema-name (:resource error))
              (clojure.string/includes?
               (str (:message error))
               (str schema-name)))))
       (distinct)))

(defn render-schema [ztx sch-name & [options]]
  (let [sch (zen.core/get-symbol ztx sch-name)
        snapshot (effective-schema ztx sch-name)
        id (str sch-name)
        form-type-request
        (-> options :page :request :params (get "form-type"))
        active-tab
        (if (= "validation" form-type-request)
          :validation
          :differential)]
    [:div.zd-tabs style
     [:div {:class (cls ["tabs" (c [:space-y 2])])}

      [:input {:type "radio" :name "tabs" :id (str id "-diff")
               :checked (when (= :differential active-tab) "checked")}]
      [:label {:class (cls ["tabh" tab-cls]) :for (str id "-diff")} "Differential"]
      [:div {:class (cls ["tabe" (c :hidden [:mx 2])])} (schema-table sch ztx)]

      [:input {:type "radio" :name "tabs" :id (str id "-snap")}]
      [:label {:class (cls ["tabh" tab-cls]) :for (str id "-snap")} "Snapshot"]
      [:div {:class (cls ["tabe" (c :hidden [:mx 2])])} (schema-table snapshot ztx)]

      [:input {:type "radio" :name "tabs" :id (str id "-validate")
               :checked (when (= :validation active-tab) "checked")}]
      [:label {:class (cls ["tabh" tab-cls]) :for (str id "-validate")} "Validate"]
      [:div {:class (cls ["tabe" (c :hidden [:mx 2])])}
       (validation-tab ztx sch-name (when (= "validation" form-type-request)
                                      (-> options :page :request :params)))]

      [:input {:type "radio" :name "tabs" :id (str id "-schema-errors")}]
      [:label {:class (cls ["tabh" tab-cls]) :for (str id "-schema-errors")} "Schema errors"]
      [:div {:class (cls ["tabe" (c :hidden [:mx 2])])}
       (when-let [schema-errors (seq (get-profile-schema-errors ztx sch-name))]
         (for [error schema-errors]
           (zen-message-view sch-name error)))]]]))
