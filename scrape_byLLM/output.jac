"""Output hook.

Library calls return their result dict by default. Passing a destination via
`opts["output"]` makes the same call ALSO persist that dict as JSON — the
return value is unchanged, so writing is a pure side effect you opt into.

dest semantics:
  falsy / absent  -> no write (default; just return the object)
  True            -> write to "data/out.json"
  "<path>"        -> write to that path (parent dirs created as needed)
"""

import from os { makedirs }
import from os.path { dirname }
import from json { dumps }


def write_output(result: dict, dest: any) -> dict {
    if not dest {
        return result;
    }
    path: str = "data/out.json";
    if isinstance(dest, str) {
        path = dest;
    }
    parent: str = str(dirname(path));
    if parent {
        makedirs(parent, exist_ok=True);
    }
    with open(path, "w") as f {
        f.write(dumps(result, indent=2));
    }
    return result;
}
