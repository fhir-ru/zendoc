(ns zd.parse
  (:require clojure.zip
            zen.core))

(defn get-map-children
  [map-schema]
  (->>
   (:keys map-schema)
   (mapv
    (fn [[k v]]
      (assoc v ::key k)))))

(defn get-vector-children
  [schema]
  (if (:slicing schema)
    (let [slices (->> schema :slicing :slices get-map-children)]
      (if-let [rest (-> schema :slicing :rest)]
        (conj slices rest)
        slices))
    [(:every schema)]))

(defn zen-zipper
  [zen-schema]
  (->>
   zen-schema
   (clojure.zip/zipper
    (fn branch? [schema]
      (contains? #{'zen/map 'zen/vector} (:type schema)))
    (fn children [schema]
      (cond
        (= 'zen/map    (:type schema)) (get-map-children schema)
        (= 'zen/vector (:type schema)) (get-vector-children schema)))
    nil)
   (iterate clojure.zip/next)
   (take-while (complement clojure.zip/end?))))

(defn get-node-path
  [loc]
  (conj
   (->> loc clojure.zip/path (keep ::key) (cons 'a) vec)
   (->> loc clojure.zip/node ::key)))

