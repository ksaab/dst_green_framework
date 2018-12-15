name = "Green![dev]"
id = "GreenFramework"
version = "1.3.111"
author = "ksaab"

description = "Enhanced magic system for Don't Starve Together"
forumthread = "files/file/1877-green"

icon = "modicon.tex"
icon_atlas = "modicon.xml"

dont_starve_compatible = false 
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

all_clients_require_mod = true

api_version = 10
priority = 20

configuration_options =
{
    --[[ {
        name = optionStrings.languageTab,
        label = optionStrings.languageTab,
        options = 
        {
            {description = "", data = 0},
        }, 
        default = 0
    }, ]]
    {
        name = "tag_overflow_fix",
        label = "Tag overflow fix",
        options = 
        {
            {description = "Enabled", data = true},
			{description = "Disabled", data = false},
        },
        default = 0
    },
}