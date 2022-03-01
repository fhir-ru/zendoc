(ns zd.zen
  (:require [stylo.core :refer [c c?]]
            [clojure.string :as str]
            [clojure.edn]
            [clojure.walk]))

(defn cls [cs]
  (str/join " " (map :name cs)))

(defn contains-name? [confirms x]
  (when confirms
    (contains? (into #{} (map name confirms)) x)))

(defn type-icon [tp confirms]
  [:div {:class (c [:w 4] [:h 4]
                   :text-xs
                   :flex
                   :items-center
                   :justify-center
                   :shadow
                   [:text :gray-700]
                   [:bg :gray-300]
                   {:border-radius "4px"
                    :border "1px solid #ccc"
                    :font-size "9px"})}
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

(defn flatten-sch [res pth {tp :type :as sch} & [opts]]
  (let [res (conj res (merge opts {:type tp
                                   :confirms (if (= 'zen/vector tp)
                                               (get-in sch [:every :confirms])
                                               (:confirms sch))
                                   :path pth
                                   :enum (:enum sch)
                                   :valueset (:valueset sch)
                                   :desc (:zen/desc sch)}))]
    (cond
      (= tp 'zen/map)
      (let [ks (->> (:keys sch)
                    (sort-by (fn [[_ v]] (:row (meta v)))))]
        (loop [[[k v] & ks] ks
               res res]
          (if (nil? k)
            res
            (recur ks
             (flatten-sch res
                          (conj pth {:key k :last (empty? ks)}) v
                          {:require (contains? (:require sch) k)})))))
      (= tp 'zen/vector)
      (flatten-sch res (conj pth {:key :every :last true}) (dissoc (:every sch) :confirms))
      
      :else res)))

(defn schema-name [sym]
  (when (and sym (not (= sym 'zen/map)))
    (name sym)
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

(defn render-schema [sch & [opts]]
  [:div 
   [:style
    "
table.schema {width: 100%;}
table.schema tr:nth-child(even) {background: rgba(247,250,252,var(--bg-opacity));}
table.schema td {}
"

    ]
   [:table.schema
    [:tbody
     (for [{pth :path :as row} (flatten-sch [] [] sch {:name (:zen/name sch)})]
       [:tr
        [:td 
         (into (schema-connectors pth)
               [(type-icon (:type row) (:confirms row))
                [:div {:class (c [:ml 3])}
                 (if-let [nm (:name row)]
                   (schema-name nm)
                   (when-let [k (:key (last (:path row)))] (name k)))]
                (when (:require row)
                  [:span {:class (c [:ml 0] [:text :red-700])} "*"])])]
        [:td {:class (c [:text :blue-600])}
         (if (:confirms row)
           (str/join ", " (mapv schema-name (:confirms row)))
           (when-let [t (:type row)] (schema-name t)))
         (when (= 'zen/vector (:type row))
           "[]")]
        [:td {:class (c [:text :gray-700] :flex :items-baseline [:space-x 2] :text-sm )}
         (when-let [d (:desc row)]
           [:div {:class (c :text-sm [:text :gray-700])} d])
         (when-let [vs (:valueset row)]
           (str "vs:" (:id vs)))
         (when-let [enum (:enum row)]
           [:div {:class (c :flex :items-baseline [:space-x 1] :text-xs)}
            [:b "enum:" ]
            (for [{v :value} enum]
              [:span v ";"]

              )]
           )
         ]])]]])
