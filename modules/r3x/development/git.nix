{
  ...
}:
{
  r3x.development.git =
    { user, ... }:
    {
      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.difftastic ];
          programs.git = {
            enable = true;
            signing.format = "ssh";
            settings = {
              user.name = user.fullName or user.description or user.userName;
              user.email = user.email or "${user.userName}@example.org";
              init.defaultBranch = "main";
              pull.rebase = true;
              pager.difftool = true;
              diff.tool = "difftastic";
              difftool.prompt = false;
              difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft $LOCAL $REMOTE";
              github.user = user.userName;
              gitlab.user = user.userName;
              core.editor = user.editor or "vim";
              alias = {
                "dff" = "difftool";
                "fap" = "fetch --all -p";
                "rm-merged" =
                  "for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D";
                "recents" =
                  "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
              };
            };
            ignores = [
              ".DS_Store"
              "*.swp"
              ".direnv"
              ".envrc"
              ".envrc.local"
              ".env"
              ".env.local"
              ".jj"
              "devshell.toml"
              ".tool-versions"
              "/.github/chatmodes"
              "/.github/instructions"
              "*.key"
              "target"
              "result"
              "out"
              "old"
              "*~"
              ".aider*"
              ".crush*"
              "CRUSH.md"
              "GEMINI.md"
              "CLAUDE.md"
              ".workspaces"
              ".agents"
              ".claude"
              "AGENT*"
              "docs/superpowers"
            ];
            includes = [ ];
            lfs.enable = true;
          };

          programs.delta.enable = true;
          programs.delta.options = {
            line-numbers = true;
            side-by-side = false;
          };
        };
    };
}
