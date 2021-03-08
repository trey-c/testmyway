Without needing imports

```nim
import testmyway
testmyway "example":
  test "bools":
    check: true == true
  ...
```

When needing imports

```nim
import testmyway
testmyway "example":
  import ...
do:
  test "bools":
    check: true == true
  ...
```
