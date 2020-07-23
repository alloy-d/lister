(local {: lines} (require :tools.belt))
(import-macros {: append} :tools.belt_macros)

(lambda have_fd? []
  "Does the system have `fd` available?"

  (not= nil (os.execute "which fd >/dev/null 2>/dev/null")))

(lambda ignore_file []
  "Returns the path to an ignore file, if it exists.

  Currently, just checks for ~/.lister-ignore.
  Only used if `fd` is available."
  (let [path (.. (os.getenv "HOME") "/.lister-ignore")
        file (io.open path)]
    (if file
      (do (file:close)
        path)
      nil)))

(lambda find_command [dir]
  "What command should we run to find files?"
  (if (have_fd?)
    (string.format "fd -e taskpaper --no-ignore %s --hidden . '%s'"
                   (let [file (ignore_file)]
                     (if file
                       (.. "--ignore-file " file)
                       ""))
                   dir)
    (string.format "find '%s' -name '*.taskpaper'" dir)))

(lambda find_files [dir]
  "Get a list of the files we care about under `dir`."
  (let [cmd (io.popen (find_command dir))
        files (lines cmd)]
    (cmd:close)
    files))

{: find_files}
