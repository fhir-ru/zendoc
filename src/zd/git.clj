(ns zd.git
  (:require [clojure.java.io :as io]
            [clojure.string :as str])
  (:import [java.lang ProcessBuilder]))

(defn read-stream [s]
  (let [r (io/reader s)]
    (loop [acc []]
      (if-let [l (.readLine r)]
        (recur (conj acc l))
        acc))))

(defn proc [{dir :dir env :env args :exec}]
  (let [proc (ProcessBuilder. (into-array String args))
        _ (when dir (.directory proc (io/file dir)))
        _ (when env
            (let [e (.environment proc)]
              #_(.clear e)
              (doseq [[k v] env]
                (.put e (name k) (str v)))))]
    proc))

(defn exec [{dir :dir env :env args :exec :as opts}]
  (let [prc (proc opts)
        p (.start prc)]
    (.waitFor p)
    {:status (.exitValue p)
     :stdout (read-stream (.getInputStream p))
     :stderr (read-stream (.getErrorStream p))}))

(defn create-timeline-data
  [[[_ author date] comment files]]
  (let [author (or author "")
        comment (or comment "")
        files (or files "")
        date (or date "")]
    {:comment (-> comment
                  first
                  clojure.string/trim)

     :user (-> author
               (clojure.string/split #"\s")
               second)

     :email (-> author
                (clojure.string/split #"\s")
                last
                rest
                butlast
                (clojure.string/join))

     :time (-> date
               (clojure.string/split #"\s")
               rest
               (->> (interpose " ")
                    (apply str)
                    (clojure.string/trim)))

     :files (vec files)}))

(defn get-history
  []
  (->> (exec {:exec ["git" "log"
                               "--name-only"
                               "--date=format:%Y-%m-%d %H:%M"
                               "--no-merges"
                               "-n" "50"]})
       :stdout
       (partition-by empty?)
       (remove (fn [x] (-> x first empty?)))
       (partition 3)
       (mapv create-timeline-data)
       (group-by (fn [l] (first (str/split (:time l) #"\s" 2))))))

(comment
  (->> (zd.runner/exec {:exec ["git" "log"
                               "--name-only"
                               "--date=format:%Y-%m-%d %H:%M"
                               "--no-merges"
                               "-n" "50"]})
       :stdout
       (partition-by empty?)
       (remove (fn [x] (-> x first empty?)))
       (partition 3)
       (mapv create-timeline-data))

  {:email "rostislavantony@gmail.com",
   :time "2022-02-14 23:19",
   :comment "Update rantonov.zd",
   :user "Rostislav Antonov"}

  (get-history)


(->> (zd.runner/exec {:exec ["git" "log"
                                "--name-only"
                               "--date=format:%Y-%m-%d %H:%M"
  "--pretty=%s\t%aN\t%aE\t%ad"
                             "-n" "50"]})
     :stdout
   (partition-by empty?))

 (->> (zd.runner/exec {:exec ["git" "log"
                          ;"--name-only"
                          "--date=format:%Y-%m-%d %H:%M"
                          "--pretty=%s\t%aN\t%aE\t%ad"
                              "-n" "2"]})
      :stdout
      (mapv (fn [x] (apply hash-map (interleave [:comment :user :email :time :rest] (str/split x #"\t"))))))


  )
