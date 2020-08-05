(local filer (require :taskpaper.filer))

(lambda prompt-for-project []
  "Uses lister to find projects and fzf to select one.
  Returns the path of the selected project."

  (let [lsp "lister list-projects -hpl"
        fzf "fzf --with-nth 2.. --header-lines=1 --preview='lister show -l {1}'"
        cmdline (string.format "%s | %s" lsp fzf)
        cmd (io.popen cmdline)
        selected (cmd:read "l")]
    (cmd:close)
    (when selected
      (let [first-tab-index (selected:find "\t" 1 true)]
        (when first-tab-index
          (selected:sub 1 (- first-tab-index 1)))))))

(lambda parse-path [path]
  "Returns two values: the first part of `path`, representing the filename, and the rest of it, represeting the path within a tree."
  (let [first-colon-index (path:find ":" 1 true)
        filename-part (path:sub 1 (- first-colon-index 1))
        rest (path:sub first-colon-index)]
    (values filename-part rest)))

(lambda load-thing [path]
  "Loads and returns the thing at `path`."
  (let [(filename rest) (parse-path path)
        root (filer.load_file filename)]
    (root:look-up rest)))

(lambda choose-project []
  "Prompts for a project, then loads and returns it."
  (let [path (prompt-for-project)]
    (when path (load-thing path))))

{: choose-project}
