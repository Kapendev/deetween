# 📽 Deetween

A cool animation library for the D programming language.
Deetween is a single-file library designed to be a simple foundation for creating complex animation systems.

## Types

* EasingFunc
* TweenMode
* Tween
* Keyframe
* KeyframeGroup
* ValueSequence

## Examples

### Tween

A simple a-to-b animation that lasts 1.0 seconds.

```d
import deetween;

void main() {
    enum a = 9.0;
    enum b = 20.0;
    enum totalDuration = 1.0;
    enum dt = 0.001;

    auto tween = Tween(a, b, totalDuration, TweenMode.bomb);

    assert(tween.now == a);
    while (!tween.hasFinished) {
        float value = tween.update(dt);
        assert(value >= a && value <= b);
    }
    assert(tween.now == b);
}
```

### KeyframeGroup

A simple a-to-b animation that lasts 1.0 seconds.

```d
import deetween;

void main() {
    enum a = 9.0;
    enum b = 20.0;
    enum totalDuration = 1.0;
    enum dt = 0.001;

    auto group = KeyframeGroup(totalDuration, TweenMode.bomb);
    group.append(
        Keyframe(a, 0.0),
        Keyframe(b, totalDuration),
    );

    assert(group.length == 2);
    assert(group.now == a);
    while (!group.hasFinished) {
        float value = group.update(dt);
        assert(value >= a && value <= b);
    }
    assert(group.now == b);
    group.clear();
    assert(group.length == 0);
}
```

### ValueSequence

A simple a-to-b animation where each value lasts 0.1 seconds.

```d
import deetween;

void main() {
    enum a = 9;
    enum b = 20;
    enum valueDuration = 0.1;
    enum dt = 0.001;

    auto sequence = ValueSequence(a, b, valueDuration, TweenMode.bomb);

    assert(sequence.now == a);
    while (!sequence.hasFinished) {
        int value = sequence.update(dt);
        assert(value >= a && value <= b);
    }
    assert(sequence.now == b);
}
```

## Influences

* [Godot](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html)
* [Gween](https://github.com/tanema/gween)
* [Keyframe](https://github.com/HannesMann/keyframe)

## Credits

The easing functions were ported from JavaScript to D from [this](https://easings.net/) site.

## License

The project is released under the terms of the Apache-2.0 License.
Please refer to the LICENSE file.