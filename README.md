# 📽 Deetween

A cool animation library for the D programming language.
Deetween is a single-file library designed to provide a simple foundation for creating complex animation systems.

## Types

* EasingFunc
* TweenMode
* Tween
* Keyframe
* KeyframeGroup

## Examples

### Tween

A simple from-a-to-b animation lasting 1.0 seconds.

```d
import deetween;

void main() {
    enum a = 69;
    enum b = 420;
    enum dt = 0.01;
    enum duration = 1.0;

    auto tween = Tween(a, b, duration, &easeLinear, TweenMode.bomb);

    assert(tween.now == a);
    while (!tween.hasFinished) {
        float value = tween.update(dt);
        assert(value >= a && value <= b);
    }
    assert(tween.now == b);
}
```

### KeyframeGroup

A simple from-a-to-b animation lasting 1.0 seconds.

```d
import deetween;

void main() {
    enum a = 69;
    enum b = 420;
    enum dt = 0.01;
    enum duration = 1.0;

    auto group = KeyframeGroup(duration, &easeLinear, TweenMode.bomb);
    group.append(Keyframe(a, 0.0));
    group.append(Keyframe(b, duration));

    assert(group.now == a);
    while (!group.hasFinished) {
        float value = group.update(dt);
        assert(value >= a && value <= b);
    }
    assert(group.now == b);
}
```

A walking animation with 3 frames lasting 0.3 seconds.

```d
import deetween;

void main() {
    enum duration = 0.3;

    auto walkAnim = KeyframeGroup(duration, &easeNearest, TweenMode.loop);
    walkAnim.appendEvenly(0, 1, 2, 2);

    float dt = duration / (walkAnim.keys.length - 1) + 0.001;
    assert(walkAnim.now == walkAnim.keys[0].value);
    foreach (i; 1 .. walkAnim.keys.length - 1) {
        assert(walkAnim.update(dt) == walkAnim.keys[i].value);
    }
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