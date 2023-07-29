# 📽 Deetween

A cool animation library for the D programming language.
Deetween is a single-file library designed to provide a simple foundation for creating more complex animation systems.

## Structs

* Tween
* Keyframe
* KeyframeGroup

## Examples

### Tween

```d
import deetween;

void main() {
    enum dt = 0.01;
    enum a = 69;
    enum b = 420;

    auto tween = Tween(a, b, 1.0, TweenKind.linear, TweenMode.bomb);
    assert(tween.now == a);
    while (!tween.hasFinished) {
        float value = tween.update(dt);
        assert(value >= a && value <= b);
    }
    assert(tween.now == b);
}
```

### KeyframeGroup

```d
import deetween;

void main() {
    enum dt = 0.01;
    enum a = 69;
    enum b = 420;

    auto group = KeyframeGroup(1.0, TweenKind.linear, TweenMode.bomb);
    group.append(Keyframe(a, 0.0));
    group.append(Keyframe(b, 1.0));
    assert(group.now == a);
    while (!group.hasFinished) {
        float value = group.update(dt);
        assert(value >= a && value <= b);
    }
    assert(group.now == b);
}
```

## Influences

* [Godot](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html)
* [Gween](https://github.com/tanema/gween)
* [Keyframe](https://github.com/HannesMann/keyframe)

## License

The project is released under the terms of the Apache-2.0 License.
Please refer to the LICENSE file.