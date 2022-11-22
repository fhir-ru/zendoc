(ns zd.format
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
    (let [slices (->> schema :slicing :slices (map (fn [[k v]] (assoc (:schema v) ::key k))))]
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

(defn get-loc-zen-path
  [loc]
  (let [root (->> loc clojure.zip/root :zen/name name)]
    (conj (->> loc clojure.zip/path (keep ::key) (cons root) vec)
          (->> loc clojure.zip/node ::key))))

(defn get-loc-cardinality
  [loc]
  (let [node   (-> loc clojure.zip/node)
        parent (-> loc clojure.zip/up clojure.zip/node)]
    (format
     "%s..%s"
     (cond
       (contains? (:require parent) (::key node)) 1
       (:minItems node) (:minItems node)
       :else 0)
     (cond
       (:maxItems node) (:maxItems node)
       (= 'zen/vector (:type node)) "*"
       :else "1"))))
