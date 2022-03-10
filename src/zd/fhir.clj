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
            [zen.core]))


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
           [:span d]])])

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
    (zd.core/start ztx (merge {:port 3030} opts))
    (reset! dtx ztx))
  :ok)


(defmethod annotation :zen/schema
  [nm params]
  {:content :zen/schema :zen/schema params})

(defmethod render-content :zen/schema
  [ztx {data :data}]
  (when data
    (println :reload data
             (zen.core/read-ns ztx (symbol (namespace data)))))
  (if-let [sch (zen.core/get-symbol ztx data)]
    [:div {:class (c :border [:p 0])}
     (zd.zen/render-schema sch)]
    [:pre (str "Could not find " data)]))


(defmethod annotation :table-of
  [nm params]
  {:content :table-of :table-of params})

(defmethod render-content :table-of
  [ztx {{tbl :table-of} :annotations data :data path :path}]
  (let [items (cond->> (->> (zd.db/search ztx tbl)
                            (sort-by (or (:sort-by tbl) :title)))
                (:reverse tbl) (reverse))]
    (zd.impl/table ztx tbl items)))


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
        [:div {:class (c :flex-1)} (zd.impl/symbol-link ztx (:zd/name it))]
        [:div {:class (c :text-sm [:text :gray-500] :flex [:space-x 2])}
         (for [g (:groups it)]
                (zd.impl/symbol-link ztx g))]
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

(defn -main [& [port reload :as args]]
  (println :args args)
  (start-docs {:production (not reload)
               :port (if port (Integer/parseInt port) 3333)}))

(comment

  (start-docs {:port 3333})

  (stop-docs)

  (do 
    (zen.core/read-ns @dtx 'fhir.ru.core)
    (zen.core/read-ns @dtx 'fhir.ru.core.organization)
    (zen.core/read-ns @dtx 'fhir.ru.diag.nosology)

    :ok)

  (zen.core/get-symbol @dtx 'fhir.ru.core.organization/Organization)
  (zen.core/get-symbol @dtx 'fhir.ru.diag.nosology/unit)

  (zen.core/errors @dtx)

  

  )
