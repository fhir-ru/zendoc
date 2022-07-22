(ns zd.zen
  (:require [stylo.core :refer [c c?]]
            [clj-yaml.core]
            [zen.core]
            [zd.db]
            [clojure.string :as str]
            [clojure.edn]
            [clojure.walk]))

(defn cls [cs]
  (str/join " " (map name cs)))

(defn contains-name? [confirms x]
  (when confirms
    (contains? (into #{} (map name confirms)) x)))

(defn contains-str? [confirms x]
  (not-empty (filter #(str/includes? % (str/lower-case x)) (into #{} (map #(-> % str str/lower-case) confirms)))))


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
                   (not extension) (conj (c [:bg :gray-300]))))}
   (cond
     (contains-name? confirms "Coding") [:div.fa-solid.fa-tag]
     (contains-name? confirms "CodeableConcept") [:div.fa-solid.fa-tags]
     (contains-name? confirms "Reference") [:div.fa-solid.fa-arrow-up-right-from-square]
     (contains-str? confirms "Identifier") [:div.fa-solid.fa-fingerprint]
     (contains-str? confirms "Address") [:div.fa-solid.fa-home]
     (contains-str? confirms "Meta") [:div.fa-solid.fa-info-circle]
     (contains-str? confirms "ContactPoint") [:div.fa-solid.fa-phone]
     (contains-str? confirms "Attachment") [:div.fa.fa-file-download]
     (contains-str? confirms "Resource") [:div.fa-solid.fa-folder]
     (contains-str? confirms "Extension") [:div.fa-solid.fa-folder-plus]
     (contains-str? confirms "Annotation") [:div.fa-solid.fa-note-sticky]
     (contains-str? confirms "backboneelement") [:div.fa-solid.fa-folder]
     (or (contains-str? confirms "range") (contains-str? confirms "Period")) [:div.fa-solid.fa-clock]
     (contains-str? confirms "HumanName") [:div.fa-solid.fa-user]
     (contains-str? confirms "uri") [:div.fa-solid.fa-link]
     (contains-str? confirms "Narrative") [:div.fa.fa-pencil {:class (cls [(c {:line-height "inherit!important"})])}]
     (contains-str? confirms "duration") [:div.fa-solid.fa-ruler]

     (or
      (contains-str? confirms "coding")
      (contains-str? confirms "code")) [:div.fa-solid.fa-tag]

     (= tp 'zen/set) [:div "#{ }"]

     (and (some? confirms) (= tp 'zen/map)) [:div.fa-solid.fa-folder #_confirms]
     (= tp 'zen/case) [:div "?"]
     (or (contains-str? confirms "string")
         (= tp 'zen/string)) [:div.fa.fa-pencil {:class (cls [(c {:line-height "inherit!important"})])}]
     (or (contains-str? confirms "date") (= tp 'zen/date)) [:div.fa.fa-calendar-day]

     (or (contains-str? confirms "time")
         (= tp 'zen/datetime))
     [:div.fa.fa-clock]
     (or
      (contains-str? confirms "boolean")
      (= tp 'zen/boolean)) [:div.fa.fa-toggle-on]
     (= tp 'zen/vector) [:div "[ ]"]
     (or (contains-str? confirms "integer")
         (contains-str? confirms "age")
         (contains-str? confirms "positiveInt")
         (= tp 'zen/integer)) [:b "1"]

     (= tp 'zen/map) [:div.fa-solid.fa-folder]
     (nil? tp) [:div.fa-solid.fa-folder]
     :else (first (last (str/split (str tp) #"/"))))])


(defn format-valueset-sch [ztx valueset]
  (when valueset
    (let [schema (zen.core/get-symbol ztx (:symbol valueset))
          standart? (clojure.string/includes? (str (:uri schema)) "hl7.org/fhir/ValueSet")
          zendoc (some-> schema :zendoc)]
      {:zendoc zendoc
       :name (or (and zendoc
                      (->> (zd.db/get-doc ztx (symbol zendoc))
                           (filter #(= [:title] (:path %)))
                           (first)
                           (:data)))
                 (and standart?
                      (-> (:uri schema)
                          (str)
                          (clojure.string/split #"/")
                          (last)))
                 (:symbol valueset))
       :page-not-found
       (and (not zendoc)
            (not standart?))
       :uri (:uri schema)
       :strength-ref
       (case (:strength valueset)
         :required   "http://hl7.org/fhir/terminologies.html#required"
         :extensible "http://hl7.org/fhir/terminologies.html#extensible"
         :preferred  "http://hl7.org/fhir/terminologies.html#preferred"
         :example    "http://hl7.org/fhir/terminologies.html#example"
         nil)
       :description (:zen/desc schema)
       :strength (name (:strength valueset))})))

(defn schema-name [sym]
  (when (and sym (not (= sym 'zen/map)))
    (if (= "schema" (name sym))
      (last (str/split (namespace sym) #"\."))
      (name sym))))

(defn format-fhir-type [ztx sch & {:keys [confirms]}]
  (cond
    (:zen.fhir/reference sch)
    (let [refers (get-in sch [:zen.fhir/reference :refers])
          refers-defs (map #(zen.core/get-symbol ztx %)
                           refers)
          refers-names (map #(or (:zen.fhir/name %) (:zen.fhir/type %))
                            refers-defs)]
      (str "Reference("
           (->> refers-names
                (mapv #(schema-name %))
                distinct
                (str/join " | "))
           ")"))

    confirms
    (last (keep #(schema-name %) confirms))))

(defn sch-el->row [pth {tp :type :as sch} & [opts ztx]]
  (let [confirms (if (= 'zen/vector tp)
                   (get-in sch [:every :confirms])
                   (:confirms sch))]
    {:type tp
     :fhir-type (format-fhir-type ztx sch :confirms confirms)
     :confirms confirms
     :extension (:fhir/extensionUri sch)
     :const (-> sch :const :value)
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
     :valueset (format-valueset-sch ztx (:zen.fhir/value-set sch))
     :desc (:zen/desc sch)}))


(defn flatten-sch [res pth {tp :type :as sch} & [opts ztx]]
  (let [res (if (:skip opts)
              res
              (conj res (merge opts (sch-el->row pth sch opts ztx))))]
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
        (if (:slicing sch)
          (let [r (flatten-sch res
                               pth
                               (:every sch)
                               {:skip true}
                               ztx)
                confirm-schema (zen.core/get-symbol ztx (-> sch :every :confirms first))]
            (loop [slices (-> sch :slicing :slices seq) acc r]
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
          (flatten-sch res
                       pth
                       (:every sch)
                       {:skip true}
                       ztx))
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
                    (deep-merge (effective-schema ztx nm) acc)) sch))]
    (clear-primitives sch)))

(defn- render-schema-table-row-name [pth row]
  (into (schema-connectors pth)
        [(type-icon (:type row) (:confirms row) (:extension row))
         [:div {:class (c [:ml 3])}
          (if-let [nm (:name row)]
            (schema-name nm)
            (when-let [k (:key (last (:path row)))] (name k)))]]))


(defn- render-schema-table-row-type [row]
  (or (:fhir-type row)
      (some-> (:type row) schema-name)))

(defn- render-schema-table-row-description [row]
  (list (when-let [d (:desc row)]
          [:div {:class (c :text-xs [:text :gray-700])} d])
        (when-let [d (:const row)]
          [:div {:class (c :text-xs [:text :gray-700])}
           [:b "Fixed value: "]
           [:span {:class (c [:text :green-700])}
            d]])
        (when-let [d (:extension row)]
          (let [extension-name (last (clojure.string/split (str d) #"/"))]
            [:div {:class (c :text-xs [:text :gray-700])}
             [:b "URL: "]
             [:a {:href (str "/extension." extension-name) :target "_blank" :class (c [:text :blue-700])}
              d]]))
        (when-let [valueset (:valueset row)]
          [:div
           [:b "Binding: "]
           [:a {:href  (if (:zendoc valueset)
                         (str "/" (:zendoc valueset))
                         (:uri valueset))
                :class (if (:page-not-found valueset)
                         (c [:text :red-600])
                         (c [:text :blue-600]))}
            (:name valueset) " "]
           [:span
            "("
            [:a {:href (:strength-ref valueset)
                 :class (c [:text :blue-600])}
             (:strength valueset)]
            ") "]
           [:span (:description valueset)]])
        (when-let [enum (:enum row)]
          [:div {:class (c :flex :items-baseline [:space-x 1] :text-xs)}
           [:b "enum:"]
           (for [{v :value} enum]
             [:span v ";"])])))

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
        (render-schema-table-row-name pth row)]
       [:td {:class (c :text-sm [:px 3])}
        (:cardinality row)]
       [:td {:class (c [:text :blue-600] :text-sm [:px 3])}
        (render-schema-table-row-type row)]

       [:td {:class (c [:text :gray-700] :text-xs)}
        (render-schema-table-row-description row)]])]])

(def style
  [:style
   "
table.schema {width: 100%;}
table.schema tr:nth-child(even) {background: rgba(247,250,252,var(--bg-opacity));}
table.schema td {}
.tabs .active { border-bottom: 2px solid #888; font-weight: 500;}

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
     [:hover [:bg :gray-100]]))

(defn get-schema&path-from-error [{:keys [schema]}]
  (let [[schema? schema-or-path?] (take-last 2 (partition-by symbol? schema))]
    (if (symbol? (first schema-or-path?))
      {:schema (first schema-or-path?)
       :path   []}
      {:schema (first schema?)
       :path   (vec schema-or-path?)})))

(defn schema-path [schema path]
  (->> path
       (mapcat
        (fn [x]
          (if (= :every x)
            [x]
            [:keys x])))
       vec))

(defn get-error-schema [ztx error-message]
  (let [{:keys [schema path]} (get-schema&path-from-error error-message)]
    (when schema
      (let [schema-def        (zen.core/get-symbol ztx schema)
            error-schema-path (schema-path schema-def path)]
        (get-in schema-def error-schema-path)))))

(defn zen-message-view
  [ztx schema-name message]
  (let [error-schema (get-error-schema ztx message)]
    [:div {:class (c [:bg :red-200] :border [:p 2] [:my 2] :text-xs)}
     [:div {:class (c :font-bold)}
      (->> (:path message)
           (map #(if (keyword? %) (name %) %))
           (interpose ".")
           (apply str)
           (str schema-name "."))]
     [:div (:zen/desc error-schema)]
     (:message message)]))

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
         (zen-message-view ztx schema-name error))
       (when (get http-params "data")
         [:div {:class (c [:text :green-500])}
          [:ul {:class "fa-ul"}
           [:li {:class (c :list-none)}
            [:span {:class "fa-li"} [:i {:class ["fa-solid" "fa-check-square"]}]]
            "Ресурс прошел валидацию."]]]))]))

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

(defn render-tabs [sch-name tabs active]
  (let [id (str sch-name)]
    [:div style
     [:div {:class (cls ["tabs" (c [:space-y 2])])}
      (for [[tab-key {tab-name :title tab-content :content}] tabs]
        (list [:input {:type "radio" :name (str "tabs" id) :id (str id "-" tab-key)
                       :checked (when (= tab-key active) "checked")}]
              [:label {:class (cls ["tabh" tab-cls]) :for (str id "-" tab-key)} tab-name]
              [:div {:class (cls ["tabe" (c :hidden [:mx 2])])} tab-content]))]]))

(defn render-schema [ztx sch-name & [options]]
  (let [sch (zen.core/get-symbol ztx sch-name)
        snapshot (effective-schema ztx sch-name)
        id (str sch-name)
        form-type-request
        (-> options :page :request :params (get "form-type"))
        active-tab
        (if (= "validation" form-type-request)
          :validate
          :differential)]
    (render-tabs id
                 {:differential {:title "Differential"
                                 :content (schema-table sch ztx)}
                  :snapshot {:title "Snapshot"
                             :content (schema-table snapshot ztx)}
                  :validate {:title "Validate"
                             :content
                             (validation-tab ztx sch-name (when (= "validation" form-type-request)
                                                            (-> options :page :request :params)))}
                  :schema-errors {:title "Schema errors"
                                  :content
                                  (when-let [schema-errors
                                             (seq (get-profile-schema-errors ztx sch-name))]
                                    (for [error schema-errors]
                                      (zen-message-view ztx sch-name error)))}}
                 active-tab)))
