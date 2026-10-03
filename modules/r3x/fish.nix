{
  den,
  ...
}:
{
  r3x.fish = {
    includes = [ (den.provides.user-shell "fish") ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          fzf
          eza
          bat
          fd
          ripgrep
          bottom
          nix-your-shell
        ];

        programs.fzf.enable = true;

        programs.fish = {
          enable = true;

          interactiveShellInit = ''
            ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source

            fish_hybrid_key_bindings
            set fish_cursor_default     block      blink
            set fish_cursor_insert      line       blink
            set fish_cursor_replace_one underscore blink
            set fish_cursor_visual      block
          '';

          plugins = [
            {
              name = "bass";
              inherit (pkgs.fishPlugins.bass) src;
            }
            {
              name = "fzf-fish";
              inherit (pkgs.fishPlugins.fzf-fish) src;
            }
          ];

          shellAbbrs = {
            # Modern CLI tools
            ls = "eza";
            l = "eza -l";
            ll = "eza -l -@ --git";
            tree = "eza -T";
            cat = "bat";
            grep = "rg";
            find = "fd";
            top = "btm";
            ".." = "cd ..";

            # Nix shortcuts
            nd = "nix develop";
            nr = "nix run";
            nf = "fd --glob '*.nix' -X nixfmt {}";

            # Jujutsu (jj)
            jb = "jj bookmark";
            jc = "jj commit -i";
            jd = {
              expansion = "jj describe -m \"%\"";
              setCursor = true;
            };
            jdd = "jj diff";
            jdt = "jj show --tool difft";
            je = "jj edit";
            jf = "jj git fetch";
            jg = "jj git";
            jl = "jj log";
            jm = "jj bookmark set main -r @";
            jn = "jj new";
            jN = {
              expansion = "jj new -m \"%\"";
              setCursor = true;
            };
            jp = "jj git push";
            jr = "jj rebase";
            js = "jj show --stat --no-pager";
            jss = "jj show --summary --no-pager";
            ju = "jjui";

            # Git
            lg = "lazygit";
            gc = "git commit";
            gb = "git branch";
            gd = "git diff";
            gs = "git status";
            gco = "git checkout";
            gcb = "git checkout -b";
            gp = "git pull --rebase --no-commit";
            gfp = "git push --force-with-lease";
            gfap = "git fetch --all -p";
            ga = "git commit --amend --reuse-message HEAD --all";
            gcm = "git commit --all --message";
          };

          functions = {
            fish_greeting = "";

            fish_hybrid_key_bindings = {
              description = "Vi-style bindings that inherit emacs-style bindings in all modes";
              body = ''
                for mode in default insert visual
                    fish_default_key_bindings -M $mode
                end
                fish_vi_key_bindings --no-erase
              '';
            };

            __hm_generation_reload = {
              description = "Reload fish when Home Manager generation changes";
              onEvent = "fish_prompt";
              body = ''
                set -l hm_gen_file ~/.local/state/home-manager/gcroots/current-home
                if test -L $hm_gen_file
                  set -l current_gen (readlink $hm_gen_file)
                  if set -q __hm_last_generation; and test "$__hm_last_generation" != "$current_gen"
                    echo "🔄 Home Manager generation changed, reloading fish..."
                    set -e __hm_last_generation
                    exec fish
                  end
                  set -g __hm_last_generation $current_gen
                end
              '';
            };

            envsource = {
              description = "Load environment variables from a .env file";
              body = ''
                for line in (cat $argv | grep -v '^\s*#' | grep -v '^\s*$')
                    set item (string split -m 1 '=' $line)
                    if test (count $item) -eq 2
                        set -gx $item[1] $item[2]
                        echo "Exported key $item[1]"
                    end
                end
              '';
            };

            jj-git-init = {
              description = "Initialize jj to follow git branch";
              argumentNames = [ "branch" ];
              body = ''
                jj git init --colocate
                jj bookmark track "$branch@origin"
                jj config set --repo "revset-aliases.'trunk()'" "$branch@origin"
              '';
            };

            nixos-opt = {
              description = "Open a browser on search.nixos.org for options";
              body = ''open "https://search.nixos.org/options?sort=relevance&query=$argv"'';
            };

            nixos-pkg = {
              description = "Open a browser on search.nixos.org for packages";
              body = ''open "https://search.nixos.org/packages?sort=relevance&query=$argv"'';
            };

            repology-nixpkgs = {
              description = "Open a browser on search for nixpkgs on repology.org";
              body = ''open "https://repology.org/projects/?inrepo=nix_unstable&search=$argv"'';
            };
          };
        };
      };
  };
}
