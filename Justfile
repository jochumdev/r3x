username := `whoami`
hostname := `hostname -s`
system := `nix-instantiate --raw --strict --eval -E builtins.currentSystem`

import 'just/local.just'
import 'just/remote.just'
import 'just/u2f.just'

help:
    just -l

fmt *args:
    fmtt {{ args }}

# ci test="" *args:
#     nix-unit --expr "(import ./.).ci \"{{ system }}\" \"{{ test }}\"" {{ args }}
