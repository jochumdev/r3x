{
  users,
  ...
}:
{
  den.aspects."r3j0".includes = [
    users.r3j0.helix
  ];

  users.r3j0.helix = {
    homeManager =
      { pkgs, ... }:
      {
        programs.helix = {
          enable = true;
          defaultEditor = true;

          settings = {
            theme = "ayu_evolve";

            editor = {
              cursorline = true;
              mouse = true;
              true-color = true;
              undercurl = true;
              line-number = "relative";
              bufferline = "multiple";
              color-modes = true;
              rulers = [
                80
                120
              ];
              end-of-line-diagnostics = "hint";
              auto-format = false;

              inline-diagnostics = {
                cursor-line = "error";
                other-lines = "disable";
              };

              indent-guides = {
                character = "╎";
                render = true;
              };

              statusline = {
                left = [
                  "mode"
                  "spinner"
                  "version-control"
                  "file-name"
                  "read-only-indicator"
                  "file-modification-indicator"
                ];
                right = [
                  "diagnostics"
                  "selections"
                  "register"
                  "position"
                  "total-line-numbers"
                  "file-encoding"
                ];
              };

              lsp = {
                auto-signature-help = false;
                display-messages = true;
              };

              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };

              file-picker = {
                hidden = false;
              };
            };

            keys = {
              normal = {
                y = "yank_to_clipboard";
                p = "paste_clipboard_after";
                P = "paste_clipboard_before";
              };

              insert = {
                up = "no_op";
                down = "no_op";
                left = "no_op";
                right = "no_op";
                pageup = "no_op";
                pagedown = "no_op";
                home = "no_op";
                end = "no_op";
              };
            };
          };

          languages = {
            language-server = {
              harper-ls = {
                command = "${pkgs.harper}/bin/harper-ls";
                args = [ "--stdio" ];
              };

              gopls = {
                command = "${pkgs.gopls}/bin/gopls";
                config = {
                  gofumpt = true;
                  staticcheck = true;
                  vulncheck = "Imports";
                  usePlaceholders = true;
                  analyses = {
                    unusedfunc = true;
                    unusedparams = true;
                    unreachable = true;
                    unusedvariable = true;
                  };
                  hints = {
                    compositeLiteralTypes = true;
                  };
                };
              };

              vscode-json-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
                args = [ "--stdio" ];
                config = {
                  json = {
                    validate.enable = true;
                    format.enable = false;
                  };
                  jsonc = {
                    validate.enable = true;
                    format.enable = false;
                  };
                  provideFormatter = false;
                };
              };

              vscode-html-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
                args = [ "--stdio" ];
              };

              vscode-css-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
                args = [ "--stdio" ];
              };

              phpactor = {
                command = "${pkgs.phpactor}/bin/phpactor";
                args = [ "language-server" ];
              };

              pylsp = {
                command = "${pkgs.python3Packages.python-lsp-server}/bin/pylsp";
                config.pylsp.plugins = {
                  rope.enabled = true;
                  ruff.enabled = true;
                  pylsp_mypy = {
                    enabled = true;
                    live_mode = true;
                  };
                };
              };

              ty = {
                command = "${pkgs.ty}/bin/ty";
                config = {
                  inlayHints.callArgumentNames = false;
                  experimental = {
                    rename = true;
                    autoImport = true;
                  };
                };
              };

              basedpyright = {
                command = "${pkgs.basedpyright}/bin/basedpyright";
                args = [ "--stdio" ];
              };

              ruff = {
                command = "${pkgs.ruff}/bin/ruff";
                args = [ "server" ];
              };

              typescript-language-server = {
                command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
                args = [
                  "--stdio"
                  "--tsserver-path=${pkgs.typescript}/lib/node_modules/typescript/lib"
                ];
              };

              yaml-language-server = {
                command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
                args = [ "--stdio" ];
              };

              rust-analyzer = {
                command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
                config = {
                  check.command = "clippy";
                  cargo.features = "all";
                };
              };

              marksman = {
                command = "${pkgs.marksman}/bin/marksman";
                args = [ "server" ];
              };

              lua-language-server = {
                command = "${pkgs.lua-language-server}/bin/lua-language-server";
              };
            };

            language = [
              {
                name = "go";
                indent = {
                  tab-width = 2;
                  unit = " ";
                };
                auto-format = true;
                language-servers = [ "gopls" ];
              }
              {
                name = "git-commit";
                language-servers = [ "harper-ls" ];
              }
              {
                name = "rust";
                auto-format = false;
                language-servers = [ "rust-analyzer" ];
              }
              {
                name = "json";
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "json"
                  ];
                };
              }
              {
                name = "jsonc";
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "jsonc"
                  ];
                };
              }
              {
                name = "javascript";
                language-servers = [
                  "typescript-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "js"
                  ];
                };
              }
              {
                name = "typescript";
                language-servers = [
                  "typescript-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "ts"
                  ];
                };
              }
              {
                name = "jsx";
                language-servers = [
                  "typescript-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "jsx"
                  ];
                };
              }
              {
                name = "tsx";
                language-servers = [
                  "typescript-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "tsx"
                  ];
                };
              }
              {
                name = "markdown";
                language-servers = [
                  "marksman"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "md"
                  ];
                };
              }
              {
                name = "html";
                language-servers = [
                  "vscode-html-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "html"
                  ];
                };
              }
              {
                name = "css";
                language-servers = [
                  "vscode-css-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "css"
                  ];
                };
              }
              {
                name = "yaml";
                formatter = {
                  command = "${pkgs.deno}/bin/deno";
                  args = [
                    "fmt"
                    "-"
                    "--ext"
                    "yaml"
                  ];
                };
              }
              {
                name = "toml";
                auto-format = true;
                language-servers = [ "tombi" ];
                formatter = {
                  command = "${pkgs.tombi}/bin/tombi";
                  args = [
                    "format"
                    "-"
                  ];
                };
              }
              {
                name = "lua";
                language-servers = [
                  "lua-language-server"
                  "harper-ls"
                ];
                formatter = {
                  command = "${pkgs.stylua}/bin/stylua";
                  args = [ "-" ];
                };
              }
              {
                name = "nu";
                auto-format = true;
                formatter = {
                  command = "${pkgs.topiary}/bin/topiary";
                  args = [
                    "format"
                    "--language"
                    "nu"
                  ];
                };
              }
            ];
          };
        };
      };
  };
}
