(ns zd.fhir
  (:require [zd.core]
            [zd.methods :refer [annotation render-content render-block render-key inline-method]]
            [stylo.core :refer [c]]
            [zd.db]
            [clojure.string :as str]
            [clj-yaml.core]
            [cheshire.core]
            [zd.zen]
            [zd.git]
            [zen.core]
            [clojure.java.shell]
            [clojure.pprint]
            [zen.dev]
            [clojure.java.io]
            [zd.format]
            [clojure.zip])
  (:import javax.xml.transform.TransformerFactory
           javax.xml.transform.stream.StreamSource
           javax.xml.transform.stream.StreamResult
           java.io.StringWriter
           java.io.StringReader))

(defmethod zd.methods/inline-function :ztx-get
  [ztx m path]
  (if-let [value (get-in @ztx path)]
    (if (string? value)
      value
      [:pre [:code {:class (str "language-clojure")}
                 (with-out-str (clojure.pprint/pprint value))]])
    [:div "Could not find " (pr-str path)]))


;; NOTE: to fix YAML parser producing lazy seqs and ordered maps/sets
;; lazy seqs can't be indexed and all of them ugly printed
;; JSON parser doesn't do such things, this patch makes YAML parser behave like JSON parser
(extend-protocol clj-yaml.core/YAMLCodec
  java.util.LinkedHashMap
  (clj-yaml.core/decode [data keywords]
    (letfn [(decode-key [k]
              (if keywords
                ;; (keyword k) is nil for numbers etc
                (or (keyword k) k)
                k))]
      (into {}
            (for [[k v] data]
              [(-> k (clj-yaml.core/decode keywords) decode-key) (clj-yaml.core/decode v keywords)]))))

  java.util.LinkedHashSet
  (clj-yaml.core/decode [data keywords]
    (into #{} data))

  java.util.ArrayList
  (clj-yaml.core/decode [data keywords]
    (mapv #(clj-yaml.core/decode % keywords) data)))


(defmethod annotation :video
  [nm params]
  {:content :video})

(defmethod annotation :disc
  [nm params]
  {:disc params})

(defn render-video [link & [opts]]
  [:div {:class (c [:px 0] [:py 2] [:bg :white])}
   (if (or (str/starts-with? link "https://youtu.be")
           (str/starts-with? link "https://www.youtube.com"))
     [:iframe {:src (str "https://www.youtube.com/embed/" (last (str/split link #"/")))
               :width (or  (:width opts) "560")
               :height (or (:height opts) "315")
               :frameborder 0
               :allow "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"}]
     
     [:div 
      [:video {:width "100%" :height "300px" :controls "controls"}
       [:source {:src link :type "video/mp4"}]]])])



(defmethod render-content :video
  [ztx {data :data}]
  (render-video data))

(defn fhir-constraints-filed
  [label content]
  (when (seq content)
    [:div {:class (c :text-xs :flex [:py 0.5] [:ml 1])}
     [:div {:class (c [:w "80px"])}
      [:span label]]
     [:span content]]))

(defn get-node-type
  [ztx node]
  (let [refers (get-in node [:zen.fhir/reference :refers])]
    (if (seq refers)
      (zd.zen/map-reference ztx refers)
      (let [confirms-schema (->> node :confirms first (zen.core/get-symbol ztx))]
        [:a {:class zd.zen/reference-style :href (zd.zen/calc-ref confirms-schema)}
         (:zen.fhir/type confirms-schema)]))))

(defn xsl-transform
  [xsl-file-path xml-string]
  (let [xsl-file (clojure.java.io/file xsl-file-path)
        transformer (.newTransformer
                     (javax.xml.transform.TransformerFactory/newInstance)
                     (new javax.xml.transform.stream.StreamSource xsl-file))
        result-writer (new java.io.StringWriter)]
    (.transform transformer
                (new javax.xml.transform.stream.StreamSource
                     (new java.io.StringReader xml-string))
                (new javax.xml.transform.stream.StreamResult result-writer))
    (->> result-writer .getBuffer .toString)))

(defmethod render-content :xsl-transformer
  [ztx params]
  (let [xsl-files (->> (:data params)
                       (:xsl-path)
                       (clojure.java.io/file)
                       (file-seq)
                       (filter (memfn isFile))
                       (map
                        (fn [file]
                          {:name (.getName file)})))
        xml-files (->> (:data params)
                       (:xml-path)
                       (clojure.java.io/file)
                       (file-seq)
                       (filter (memfn isFile))
                       (map
                        (fn [file]
                          {:name (.getName file) :content (slurp file)})))
        response (-> params :page :request :params)
        xml      (get response "xml")
        xml-example (get response "xml-example")
        xsl-name (get response "xsl")]
    [:div 
     [:div 
      [:form {:method "POST"}
       [:label {:class (c :font-medium [:text :black]) :for "xsl" } "XSL:"]
       [:div {:class (c [:mb 4])}
        [:select {:name "xsl" :id "xsl" :class (c :border [:px 4] [:py 1] :rounded)}
         [:option {:disabld true :selected (empty? xsl-name)}]
         (for [xsl-file xsl-files]
           [:option {:value (:name xsl-file)
                     :selected (= (:name xsl-file) xsl-name)}
            (:name xsl-file)])]]
       
       [:label {:class (c :font-medium [:text :black]) :for "xml" } "XML:"]
       [:div {:class (c [:mb 4])}
        [:select {:name "xml-example" :id "xml-example" :class (c :border [:px 4] [:py 1] :rounded)}
         [:option {:disabld true :selected (empty? xml-example)}]
         (for [xml-file xml-files]
           [:option {:value (:content xml-file)
                     :selected (= (:content xml-file) xml-example)}
            (:name xml-file)])]]
       [:div [:textarea {:class (c :border [:px 4] [:py 1] :rounded :w-full) :name "xml" :id "xml" :rows 20} xml]]
       [:button {:type "submit" :class (c [:px 5] [:py 2] [:mt 4] :border [:bg :gray-200] :rounded)} "Transform"]]
      (when (and xml xsl-name)
        (let [xsl-path (str (:xsl-path (:data params)) "/" xsl-name)]
          [:div
           [:label {:class (c :font-medium [:text :black] :block)}"Result:"]
           [:pre
            [:code
             (try 
               (xsl-transform xsl-path xml)
               (catch Exception ex
                 (ex-message ex)))]]]))]
     [:script
      "const xmlExample = document.querySelector('#xml-example');
       const xml        = document.querySelector('#xml');
       xmlExample.addEventListener('change', function (event) { xml.value = event.target.value});"]]))

(defmethod annotation :xsl-transformer
  [nm params]
  {:content :xsl-transformer :xsl-transformer params})

(defmethod render-content :fhir-constraints
  [ztx params]
  (let [schema (->> params :data (zen.core/get-symbol ztx))
        locs   (->>
                (zd.format/zen-zipper schema)
                (filter
                 (fn [loc]
                   (let [node (clojure.zip/node loc)]
                     (keyword? (:zd.format/key node))))))
        schema-id (name (:zen/name schema))]
    
    [:div
     [:div
      [:div {:class (c [:bg :gray-300] [:px 1])}
       [:b schema-id]]
      [:div {:class (c [:py 2])}
       (fhir-constraints-filed "Element id" schema-id)
       (fhir-constraints-filed "Definition" (:zen/desc schema))
       (fhir-constraints-filed "Cardinality" "0..*")
       (fhir-constraints-filed "Type" (get-node-type ztx schema))
       (fhir-constraints-filed "Comments" (:zen.fhir/comment schema))
       (fhir-constraints-filed "Invariants"
                               (for [c (:zen.fhir/constraint schema)]
                                 [:div {:class (c [:space-y 2])}
                                  [:b (:key c)]
                                  [:div (:human c)]
                                  [:div (:expression c)]]))]]
     (for [loc locs]
       (let [id     (some->> loc zd.format/get-loc-zen-path (map name) (interpose ".") (apply str))
             node   (clojure.zip/node loc)]
         [:div
          [:div {:class (c [:bg :gray-300] [:px 1])}
           [:b id]]
          [:div {:class (c [:py 2])}
           (fhir-constraints-filed "Element id" id)
           (fhir-constraints-filed "Definition" (:zen/desc node))
           (fhir-constraints-filed "Cardinality" (zd.format/get-loc-cardinality loc))
           (fhir-constraints-filed "Terminology Binding"
                                   (when-let [valueset (zd.zen/format-valueset-sch ztx (:zen.fhir/value-set node))]
                                     (zd.zen/valueset-view valueset)))
           (fhir-constraints-filed "Type" (get-node-type ztx node))
           (fhir-constraints-filed "Comments" (:zen.fhir/comment node))
           (fhir-constraints-filed "Invariants" (for [c (:zen.fhir/constraint node)]
                                                  [:div {:class (c [:space-y 2])}
                                                   [:b (:key c)]
                                                   [:div (:human c)]
                                                   [:div (:expression c)]]))]]))]))

(defmethod annotation :fhir-constraints
  [nm params]
  {:content :fhir-constraints :fhir-constraints params})

(defmethod render-key
  [:video]
  [_ {data :data}]
  (render-video data))

(defmethod render-key
  [:zd/debug]
  [_ {data :data :as block}]
  [:div 
   [:h3 "Debug page"]
   [:pre {:class (c :text-sm)}
    [:code {:class (str "language-json hljs")}
     (cheshire.core/generate-string
      (get-in block [:page]) {:pretty true})]]])

;; discussion
(defmethod inline-method :d
  [ztx m d]
  [:a {:href (str "https://github.com/fhir-ru/core/discussions/" d)
       :target "_blank"
       :class (c [:text :blue-500] [:space-x 0.5])}
   [:i.fa-regular.fa-comments {:class (name (c [:text :blue-400] :text-sm))}]
   [:span d]])

(defmethod zd.methods/title-actions
  :override
  [ztx {ann :annotations data :data path :path :as block}]
  [:div (when-let [d (:disc ann)]
          [:a {:href (str "https://github.com/fhir-ru/core/discussions/" d)
               :target "_blank"
               :class (c [:text :blue-500] [:space-x 0.5] {:font-weight 400}
                         [:hover [:text :blue-600]])}
           [:i.fa-regular.fa-comments {:class (name (c [:text :blue-400] :text-sm))}]
           [:span {:class (c :text-sm)} d]])])

(defonce dtx (atom nil))

(defn stop-docs []
  (when-let [dtx @dtx] 
    (zd.core/stop dtx)))

(defn start-docs [opts]
  (stop-docs)
  (let [pth (str (System/getProperty "user.dir") "/docs")
        zrc (str (System/getProperty "user.dir") "/zrc")
        ztx (zen.core/new-context {:zd/paths [pth] :paths [pth zrc]})]
    (zen.core/read-ns ztx 'fhir.ru.core)
    (zd.core/start ztx (merge {:port 3030}
                              opts))
    (reset! dtx ztx)
    (when-not (:production opts)
      (zen.dev/watch ztx)))
  :ok)


(defmethod annotation :zen/schema
  [nm params]
  {:content :zen/schema :zen/schema params})

(defmethod render-content :zen/schema
  [ztx {data :data :as options}]
  (when data
    (println :reload data
             (zen.core/read-ns ztx (symbol (namespace data)))))
  (if-let [sch (zen.core/get-symbol ztx data)]
    [:div {:class (c )}
     (zd.zen/render-schema ztx data options)]
    [:pre (str "Could not find " data)]))


(defmethod annotation :tabs
  [nm params]
  {:block :plain :content :tabs :tabs params})

(defmethod render-content :tabs
  [ztx  {ann :annotations data :data path :path :as options}]
  (let [path (:path options)
        data-blocks (->> (get-in options [:page :doc])
                         (filter #(#{:tab-title :tab-content} (get-in % [:annotations :type])))
                         (filterv #(= (subvec (:path %) 0 (count path)) path)))
        blocks-order (distinct (map #(nth (:path %) (count path)) data-blocks))
        data         (reduce (fn [acc block]
                               (assoc-in acc (subvec (:path block) (count path))
                                         (render-content ztx block)))
                             {}
                             data-blocks)
        ordered-data (->> blocks-order
                          (mapcat #(find data %))
                          (apply array-map))
        id (->> (:path options)
                (mapv #(str/replace % "_" "__"))
                (str/join "_"))]
    [:div {:class (str " " (when (:collapse ann) "zd-toggle") " " (when (get-in ann [:collapse :open]) "zd-open"))}
     [(keyword (str "h" (inc (count path)))) {:class (str "zd-block-title " (name (c :flex :items-baseline)))}
      [:div {:class (c :flex :flex-1)}
       (when (:collapse ann)
         [:i.fas.fa-chevron-right {:class (name (c [:mr 2] [:text :gray-500] :cursor-pointer
                                                   [:hover [:text :gray-600]]))}])
       (zd.impl/keypath path (or (:title ann) (let [k (last path)] (zd.impl/capitalize k))))]]
     [:div.zd-content
      (zd.zen/render-tabs id ordered-data (first (keys ordered-data)))]]))

(defmethod annotation :tab-title
  [nm params]
  {:block :none :type :tab-title})

(defmethod annotation :tab-content
  [nm params]
  {:block :none :type :tab-content})

(defmethod annotation :table-of
  [nm params]
  {:content :table-of :table-of params})

(defmethod render-content :table-of
  [ztx {{tbl :table-of} :annotations data :data path :path}]
  (let [items (cond->> (->> (zd.db/search ztx tbl)
                            (sort-by (or (:sort-by tbl) :title)))
                (:reverse tbl) (reverse))]
    (zd.impl/table ztx tbl items)))

(defn remove-leading-slash [v]
  (update-in v [1 :href] subs 1))

(defmethod render-content :meeting-list
  [ztx {{optx :meeting-list} :annotations data :data path :path}]
  (let [group-filter (:group optx)
        items (cond->> (->> (zd.db/search ztx {:namespace "meetings."})
                            (filter (fn [x]
                                      (if group-filter
                                        (contains? (:groups x) group-filter)
                                        true)))
                            (sort-by :date)
                            (reverse)))]
    (for [it items]
      [:div {:class (c [:py 2] [:mb 4])}
       [:div {:class (c :border-b :text-lg :flex [:space-x 4])}
        [:div {:class (c :flex-1)} (->> it
                                        :zd/name
                                        (zd.impl/symbol-link ztx)
                                        remove-leading-slash)]
        [:div {:class (c :text-sm [:text :gray-500] :flex [:space-x 2])}
         (for [g (:groups it)]
                (->> g
                     (zd.impl/symbol-link ztx)
                     remove-leading-slash))]
        [:div {:class (c :text-sm [:text :gray-500])}
         (:date it)]]
       [:div {:class (c :flex [:space-x 8] [:py 2] :text-sm)}
        [:div {:class (c :flex-1)}
         (if-let [d (:discussion it)]
           (zd.impl/render-md ztx d)
           (str (keys it)))]
        (render-video (:video it) {:width 280 :height 150})
        ]])))

(defn gh-index [ztx]
  (->> (zd.db/get-resources ztx)
       (filter (fn [x]
                 (str/starts-with? (name (:zd/name x)) "people.")))
       (reduce (fn [acc {ghn :git/names gh :github :as res}]
                 (if (or gh ghn)
                   (->> ghn
                        (reduce (fn [acc nm]
                                  (assoc acc nm res))
                                (assoc acc gh res)))
                   acc)))))

(defn gh-user [ztx gh-idx l]
  (if-let [u (get gh-idx (when-let [un (:user l)] (str/trim un)))]
    (zd.impl/symbol-link ztx (:zd/name u))
    [:b (or (:user l) (:email l))]))

(defmethod render-key
  [:git/timeline]
  [ztx {data :data :as block}]
  (let [gh-idx (gh-index ztx)]
    [:div
     (for [[date ls] (->> (zd.git/get-history)
                          (sort-by first)
                          (reverse))]
       [:div
        [:div {:class (c :border-b :font-bold [:mt 2])} date]
        (for [l (reverse (sort-by :time ls))]
          [:div
           [:div {:class (c :flex :items-baseline [:space-x 2] [:ml 0] [:py 1])}
            [:div {:class (c [:text :gray-600])}(last (str/split (:time l) #"\s" 2))]
            [:div (gh-user ztx gh-idx l)]
            [:div (:comment l)]]
           [:ul {:class (c [:ml 6])}
            (->> (:files l)
                 (filter (fn [x] (and (str/starts-with? x "docs/")
                                     (str/ends-with? x ".zd"))))
                 (map (fn [x] (symbol (-> (str/replace x #"(^docs/|\.zd$)" "")
                                         (str/replace #"/" ".")))))
                 (sort)
                 (mapv (fn [x] [:li
                               (zd.impl/symbol-link ztx x)]))
                 (apply conj [:div]))]])])]))

(defmethod zd.core/op ::readme-redir
  [_ztx _op _req]
  {:status  302
   :headers {"Location" "/wiki/readme"}})

(def routes
  {:GET {:op ::readme-redir}})

(defn -main [& [port reload :as args]]
  (println :args args)
  ;; (clojure.java.shell/sh "npm" "update" :dir "zrc")
  (start-docs {:production (not reload)
               :route-map routes
               :port (if port (Integer/parseInt port) 3333)
               :ip "127.0.0.1"}))

(comment
  (start-docs {:port 3333
               :route-map routes})

  (stop-docs)

  (do 
    (zen.core/read-ns @dtx 'fhir.ru.core)
    (zen.core/read-ns @dtx 'fhir.ru.core.organization)
    (zen.core/read-ns @dtx 'fhir.ru.diag.nosology)
    (zen.core/read-ns @dtx 'fhir.ru.diag.nu)

    :ok)

  (zen.core/get-symbol @dtx 'fhir.ru.core.organization/Organization)
  (zen.core/get-symbol @dtx 'fhir.ru.diag.nosology/DiagnosisNosology)
  (zen.core/get-symbol @dtx 'fhir.ru.diag.nu/DsCondition)

  (zen.core/errors @dtx)

  

  )
