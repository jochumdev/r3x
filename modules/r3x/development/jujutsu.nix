# See https://github.com/jj-vcs/jj/discussions/5812
{
  ...
}:
let
  jj-settings =
    { pkgs, user }:
    {
      user.name = user.fullName or user.description or user.userName;
      user.email = user.email or "${user.userName}@example.org";
      revsets.log = "default()";
      revset-aliases = {
        "trunk()" =
          "coalesce(present(main@origin), present(main), present(master@origin), present(master), root())";
        "compared_to_trunk()" = "(trunk()..@):: | (trunk()..@)-";
        "immutable_heads()" = "builtin_immutable_heads() | remote_bookmarks()";
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
        "default_log()" = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())";
        "default()" = "coalesce(trunk(),root())::present(@) | ancestors(visible_heads() & recent(), 2)";
        "recent()" = "committer_date(after:'1 week ago')";
      };
      template-aliases = {
        "format_short_id(id)" = "id.shortest().upper()";
        "format_short_change_id(id)" = "format_short_id(id)";
        "format_short_signature(signature)" = "signature.email()";
        "format_timestamp(timestamp)" = "timestamp.ago()";
      };
      "--scope" = jj-scopes { inherit pkgs; };
      ui = jj-ui { inherit pkgs user; };
      signing = {
        behaviour = "own";
        backend = "ssh";
        key = user.signingKey or "~/.ssh/id_ed25519.pub";
      };
      aliases = jj-aliases;
    };

  jj-diff-formatter =
    { pkgs }:
    [
      (pkgs.lib.getExe pkgs.delta)
      "$left"
      "$right"
    ];

  jj-ui =
    { pkgs, user }:
    {
      default-command = [
        "status"
        "--no-pager"
      ];
      editor = user.editor or "hx";
      diff-formatter = jj-diff-formatter { inherit pkgs; };
      diff-editor = user.diffEditor or user.editor or ":builtin";
      conflict-marker-style = "git";
      movement.edit = false;
    };

  jj-scopes =
    { pkgs }:
    [
      {
        "--when".commands = [
          "diff"
          "show"
        ];
        ui.pager = (pkgs.lib.getExe pkgs.delta);
        ui.diff-formatter = jj-diff-formatter { inherit pkgs; };
      }
    ];

  jj-aliases = {
    tug = [
      "bookmark"
      "move"
      "--from"
      "closest_bookmark(@-)"
      "--to"
      "@-"
    ];
    lr = [
      "log"
      "-r"
      "default() & recent()"
    ];
    s = [ "show" ];
    sq = [
      "squash"
      "-i"
    ];
    sU = [
      "squash"
      "-i"
      "-f"
      "@+"
      "-t"
      "@"
    ];
    su = [
      "squash"
      "-i"
      "-f"
      "@"
      "-t"
      "@+"
    ];
    sd = [
      "squash"
      "-i"
      "-f"
      "@"
      "-t"
      "@-"
    ];
    sD = [
      "squash"
      "-i"
      "-f"
      "@-"
      "-t"
      "@"
    ];
    l = [
      "log"
      "-r"
      "compared_to_trunk()"
      "--config"
      "template-aliases.'format_short_id(id)'='id.shortest().upper()'"
      "--config"
      "template-aliases.'format_short_change_id(id)'='id.shortest().upper()'"
      "--config"
      "template-aliases.'format_timestamp(timestamp)'='timestamp.ago()'"
    ];
    ll = [
      "log"
      "-r"
      ".."
    ];
  };
in
{
  r3x.development.jujutsu =
    { user, ... }:
    {
      homeManager =
        { pkgs, ... }:
        let
          jjui-wrapped = pkgs.writeShellApplication {
            name = "jjui";
            text = ''
              # ask for password if key is not loaded, before jjui
              ssh-add -l || ssh-add
              ${pkgs.lib.getExe pkgs.jjui} "$@"
            '';
          };
        in
        {
          home.packages = [
            jjui-wrapped
            pkgs.lazyjj
          ];
          programs.jujutsu = {
            enable = true;
            settings = jj-settings { inherit pkgs user; };
          };
        };
    };
}
