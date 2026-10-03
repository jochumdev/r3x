{ ... }:
{
  r3x.browser = {
    homeManager =
      { ... }:
      {
        programs.librewolf = {
          enable = true;
          # Enable WebGL, cookies and history
          settings = {
            "webgl.disabled" = false;
            "privacy.resistFingerprinting" = false;
            "privacy.sanitize.sanitizeOnShutdown" = false;
            "privacy.clearOnShutdown.history" = false;
            "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
            "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
            "privacy.clearOnShutdown.cookies" = false;
            "network.cookie.lifetimePolicy" = 0;
          };
        };

        home.sessionVariables = {
          BROWSER = "librewolf";
          DEFAULT_BROWSER = "librewolf";
        };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = "librewolf.desktop";
            "x-scheme-handler/http" = "librewolf.desktop";
            "x-scheme-handler/https" = "librewolf.desktop";
            "x-scheme-handler/about" = "librewolf.desktop";
            "x-scheme-handler/unknown" = "librewolf.desktop";
          };
        };
      };
  };
}
