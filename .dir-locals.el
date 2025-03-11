((yaml-ts-mode
  . ((eglot-workspace-configuration
      . (:yaml
	 ;; See https://github.com/redhat-developer/yaml-language-server?tab=readme-ov-file#language-server-settings
         (:format
	  (:enable t
	   :singleQuote nil
	   :bracketSpacing t
	   :proseWrap "preserve"
	   :printWidth 80)
          :validate t
          :hover t
          :completion t
	  :schemas (https://raw.githubusercontent.com/chainguard-dev/melange/refs/heads/main/pkg/config/schema.json ["/*.yaml"]
                    https://json.schemastore.org/yamllint.json ["/*.yaml"])
	  :schemaStore (:enable t)

         ;; custom tags for the parser to use
         :customTags nil
         :maxItemsComputed 5000))))))
