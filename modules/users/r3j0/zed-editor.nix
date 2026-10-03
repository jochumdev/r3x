{
  ...
}:
{
  users.r3j0.zed-editor = {
    homeManager =
      {
        pkgs,
        ...
      }:
      {
        programs.zed-editor = {
          enable = true;
          extensions = [
            "ayu-darker"
            "codebook"
            "dockerfile"
            "fff-mcp"
            "fish"
            "git-firefly"
            "golangci-lint"
            "html"
            "just"
            "just-ls"
            "kdl"
            "lua"
            "make"
            "nix"
            "openfga"
            "sql"
            "tombi"
            "xml"
          ];
          extraPackages = with pkgs; [
            nil
            nixd
            nixfmt
            golangci-lint
            just
          ];
          themes = {
            monokai = ./dots/config/zed/themes/monokai.json;
            one_monokai = ./dots/config/zed/themes/one_monokai.json;
          };
          userSettings = {
            language_models = {
              opencode = {
                show_go_models = true;
              };
            };
            buffer_font_family = "JetBrainsMono Nerd Font Mono";
            ui_font_features = {
              calt = 1;
            };
            ui_font_size = 12;
            buffer_font_size = 12;
            preferred_line_length = 110;
            tab_size = 2;
            ssh_connections = [
              {
                host = "dev01";
                args = [ ];
                projects = [
                  { paths = [ "/home/r3j0/projects/incus-caddy-config/./" ]; }
                  { paths = [ "/home/r3j0/projects/incus-compose" ]; }
                  { paths = [ "/home/r3j0/projects/jochum.dev-v2" ]; }
                  { paths = [ "/home/r3j0/projects/komodo/./" ]; }
                  { paths = [ "/home/r3j0/projects/leafwiki-federation-demo" ]; }
                  { paths = [ "/home/r3j0/projects/leafwiki/./" ]; }
                  { paths = [ "/home/r3j0/projects/nixos/./" ]; }
                  { paths = [ "/home/r3j0/vendor/go/incus/./" ]; }
                ];
              }
              {
                host = "dev01";
                args = [ ];
                projects = [ ];
              }
            ];
            cli_default_open_behavior = "existing_window";
            project_panel.dock = "left";
            outline_panel.dock = "left";
            collaboration_panel.dock = "left";
            git_panel.dock = "left";

            agent_servers = {
              dirac.type = "registry";
              antigravity-acp = {
                type = "registry";
                env = {
                  PI_ANTIGRAVITY_ACP_OAUTH_MODE = "manual";
                };
              };
              agy-acp = {
                type = "custom";
                command = "agy-acp";
                default_config_options = {
                  model = "gemini-3.8-flash-high";
                };
              };
            };

            disable_ai = false;
            show_edit_predictions = false;

            agent = {
              sandbox_permissions = {
                network_hosts = [ "api.github.com" ];
              };
              profiles = {
                auto = {
                  name = "Auto";
                  default_model = {
                    provider = "openrouter";
                    model = "xiaomi/mimo-v2.5-pro";
                    enable_thinking = true;
                  };
                  tools = {
                    create_directory = true;
                    copy_path = true;
                    delete_path = true;
                    diagnostics = true;
                    fetch = true;
                    edit_file = true;
                    find_path = true;
                    list_directory = true;
                    grep = true;
                    move_path = true;
                    read_file = true;
                    skill = true;
                    spawn_agent = true;
                    terminal = true;
                    write_file = true;
                    ask_user = true;
                  };
                  enable_all_context_servers = false;
                  context_servers = {
                    gopls.tools = {
                      go_rename_symbol = false;
                      go_diagnostics = true;
                    };
                  };
                };
              };
              flexible = false;
              dock = "right";
              tool_permissions = {
                default = "allow";
                tools = {
                  write_file.default = "allow";
                  create_directory.default = "allow";
                };
              };
              default_profile = "auto";
              default_model = {
                effort = "xhigh";
                enable_thinking = true;
                provider = "openrouter";
                model = "qwen/qwen3.8-max-0902";
              };
              model_parameters = [ ];
            };

            context_servers = {
              fff = {
                enabled = false;
                remote = false;
                settings.settings = {
                  fff_binary_path = "fff-mcp";
                  log_level = "info";
                  no_update_check = false;
                  no_warmup = false;
                };
              };
              gopls = {
                enabled = true;
                remote = false;
                command = "gopls";
                args = [ "mcp" ];
                env = { };
              };
              ripgrep = {
                enabled = false;
                command = "npx";
                args = [
                  "-y"
                  "mcp-ripgrep@latest"
                ];
                env = { };
              };
            };

            inlay_hints.enabled = true;
            relative_line_numbers = "disabled";
            terminal = {
              shell = {
                program = "/usr/bin/nu";
              };
            };
            ui_font_family = ".ZedSans";
            use_system_path_prompts = false;
            format_on_save = "on";
            autosave = "off";
            helix_mode = true;
            vim_mode = true;
            telemetry = {
              diagnostics = false;
              metrics = false;
            };
            theme = "Ayu Darker";

            lsp = {
              golangci-lint = {
                initialization_options = {
                  command = [
                    "golangci-lint"
                    "run"
                    "--output.json.path"
                    "stdout"
                    "--show-stats=false"
                    "--output.text.path="
                  ];
                };
              };
              nil = {
                binary.path = "/run/current-system/sw/bin/nil";
                autoArchive = true;
              };
            };

            languages = {
              Go = {
                language_servers = [
                  "gopls"
                  "golangci-lint"
                ];
                formatter.external = {
                  command = "golangci-lint";
                  arguments = [
                    "fmt"
                    "--stdin"
                  ];
                };
              };
              Nix = {
                language_servers = [
                  "nil"
                  "!nixd"
                ];
                formatter.external = {
                  command = "nixfmt";
                  arguments = [
                    "--quiet"
                    "--"
                  ];
                };
              };
            };
          };
        };
      };
  };
}
