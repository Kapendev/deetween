// Copyright 2023 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: Apache-2.0

module deetween;

import math = std.math;

alias EasingFunc = float function(float x) pure nothrow @nogc @safe;

enum TweenMode {
    bomb,
    loop,
    yoyo,
}

struct Tween {
pure nothrow @nogc @safe:

    float a = 0.0f;
    float b = 0.0f;
    float time = 0.0f;
    float duration = 0.0f;
    EasingFunc f = &easeLinear;
    TweenMode mode;
    bool isYoyoing;

    this(float a, float b, float duration, EasingFunc f, TweenMode mode) {
        this.a = a;
        this.b = b;
        this.duration = duration;
        this.f = f;
        this.mode = mode;
    }

    bool hasStarted() {
        return time > 0.0f;
    }

    bool hasFinished() {
        return time >= duration;
    }

    float progress() {
        if (duration != 0.0f) {
            return time / duration;
        }
        return 0.0f;
    }

    void progress(float value) {
        if (value <= 0.0f) {
            time = 0.0f;
        } else if (value >= 1.0f) {
            time = duration;
        } else {
            time = value * duration;
        }
    }

    float now() {
        if (time <= 0.0f) {
            return a;
        } else if (time >= duration) {
            return b;
        } else {
            return ease(a, b, progress, f);
        }
    }

    float update(float dt) {
        final switch (mode) {
        case TweenMode.bomb:
            time += dt;
            if (time <= 0.0f) {
                time = 0.0f;
            } else if (time >= duration) {
                time = duration;
            }
            return now;
        case TweenMode.loop:
            time += dt;
            if (time <= 0.0f) {
                time += duration;
            } else if (time >= duration) {
                time -= duration;
            }
            return now;
        case TweenMode.yoyo:
            if (isYoyoing) {
                time -= dt;
            } else {
                time += dt;
            }
            if (time <= 0.0f) {
                time = 0.0f;
                isYoyoing = false;
            } else if (time >= duration) {
                time = duration;
                isYoyoing = true;
            }
            return now;
        }
    }

    void reset() {
        time = 0.0f;
    }
}

struct Keyframe {
pure nothrow @nogc @safe:

    float value = 0.0f;
    float time = 0.0f;

    this(float value, float time) {
        this.value = value;
        this.time = time;
    }
}

struct KeyframeGroup {
pure nothrow @safe:

    enum defaultCapacity = 16;

    Keyframe[] keys;
    float time = 0.0f;
    float duration = 0.0f;
    EasingFunc f = &easeLinear;
    TweenMode mode;
    bool isYoyoing;

    this(float duration, EasingFunc f, TweenMode mode) {
        reserve(keys, defaultCapacity);
        this.duration = duration;
        this.f = f;
        this.mode = mode;
    }

    @nogc
    bool hasStarted() {
        return time > 0.0f;
    }

    @nogc
    bool hasFinished() {
        return time >= duration;
    }

    @nogc
    float progress() {
        if (duration != 0.0f) {
            return time / duration;
        }
        return 0.0f;
    }

    @nogc
    void progress(float value) {
        if (value <= 0.0f) {
            time = 0.0f;
        } else if (value >= 1.0f) {
            time = duration;
        } else {
            time = value * duration;
        }
    }

    @nogc
    float now() {
        if (keys.length == 0) {
            return 0.0f;
        } else if (time <= 0.0f) {
            return keys[0].value;
        } else if (time >= duration) {
            return keys[$ - 1].value;
        } else {
            foreach (i; 0 .. keys.length) {
                if (time <= keys[i].time) {
                    Keyframe a = keys[i - 1];
                    Keyframe b = keys[i];
                    float weight = (time - a.time) / (b.time - a.time);
                    return ease(a.value, b.value, weight, f);
                }
            }
            return 0.0f;
        }
    }

    @nogc
    float update(float dt) {
        final switch (mode) {
        case TweenMode.bomb:
            time += dt;
            if (time <= 0.0f) {
                time = 0.0f;
            } else if (time >= duration) {
                time = duration;
            }
            return now;
        case TweenMode.loop:
            time += dt;
            if (time <= 0.0f) {
                time += duration;
            } else if (time >= duration) {
                time -= duration;
            }
            return now;
        case TweenMode.yoyo:
            if (isYoyoing) {
                time -= dt;
            } else {
                time += dt;
            }
            if (time <= 0.0f) {
                time = 0.0f;
                isYoyoing = false;
            } else if (time >= duration) {
                time = duration;
                isYoyoing = true;
            }
            return now;
        }
    }

    @nogc
    void reset() {
        time = 0.0f;
    }

    void append(Keyframe key) {
        if (keys.length == 0 || keys[$ - 1].time <= key.time) {
            keys ~= key;
        } else {
            keys ~= key;
            // Hehehe!
            foreach (i; 1 .. keys.length) {
                foreach_reverse (j; i .. keys.length) {
                    if (keys[j - 1].time > keys[j].time) {
                        Keyframe temp = keys[j - 1];
                        keys[j - 1] = keys[j];
                        keys[j] = temp;
                    }
                }
            }
        }
    }

    void appendEvenly(float[] values...) {
        foreach (i; 0 .. values.length) {
            float t;
            if (i == 0) {
                t = 0.0f;
            } else if (i == values.length - 1) {
                t = duration;
            } else {
                t = duration * (float(i) / (values.length - 1));
            }
            append(Keyframe(values[i], t));
        }
    }

    @nogc
    void remove(size_t idx) {
        int i = 0;
        while (i + 1 < keys.length) {
            keys[i] = keys[i + 1];
            i += 1;
        }
        keys = keys[0 .. $ - 1];
    }

    @nogc
    Keyframe pop() {
        if (keys.length != 0) {
            Keyframe temp = keys[$ - 1];
            keys = keys[0 .. $ - 1];
            return temp;
        } else {
            return Keyframe();
        }
    }
}

pure nothrow @nogc @safe {
    float lerp(float a, float b, float weight) {
        return a + (b - a) * weight;
    }

    float ease(float a, float b, float weight, EasingFunc f) {
        return a + (b - a) * f(weight);
    }

    float easeNearest(float x) {
        return 0.0f;
    }

    float easeLinear(float x) {
        return x;
    }

    float easeInSine(float x) {
        return 1.0f - math.cos((x * math.PI) / 2.0f);
    }

    float easeOutSine(float x) {
        return math.sin((x * math.PI) / 2.0f);
    }

    float easeInOutSine(float x) {
        return -(math.cos(math.PI * x) - 1.0f) / 2.0f;
    }

    float easeInQuad(float x) {
        return x * x;
    }

    float easeOutQuad(float x) {
        return 1.0f - (1.0f - x) * (1.0f - x);
    }

    float easeInOutQuad(float x) {
        if (x < 0.5f) {
            return 2.0f * x * x;
        } else {
            return 1.0f - math.pow(-2.0f * x + 2.0f, 2.0f) / 2.0f;
        }
    }

    float easeInCubic(float x) {
        return x * x * x;
    }

    float easeOutCubic(float x) {
        return 1.0f - math.pow(1.0f - x, 3.0f);
    }

    float easeInOutCubic(float x) {
        if (x < 0.5f) {
            return 4.0f * x * x * x;
        } else {
            return 1.0f - math.pow(-2.0f * x + 2.0f, 3.0f) / 2.0f;
        }
    }

    float easeInQuart(float x) {
        return x * x * x * x;
    }

    float easeOutQuart(float x) {
        return 1.0f - math.pow(1.0f - x, 4.0f);
    }

    float easeInOutQuart(float x) {
        if (x < 0.5f) {
            return 8.0f * x * x * x * x;
        } else {
            return 1.0f - math.pow(-2.0f * x + 2.0f, 4.0f) / 2.0f;
        }
    }

    float easeInQuint(float x) {
        return x * x * x * x * x;
    }

    float easeOutQuint(float x) {
        return 1.0f - math.pow(1.0f - x, 5.0f);
    }

    float easeInOutQuint(float x) {
        if (x < 0.5f) {
            return 16.0f * x * x * x * x * x;
        } else {
            return 1.0f - math.pow(-2.0f * x + 2.0f, 5.0f) / 2.0f;
        }
    }

    float easeInExpo(float x) {
        if (x == 0.0f) {
            return 0.0f;
        } else {
            return math.pow(2.0f, 10.0f * x - 10.0f);
        }
    }

    float easeOutExpo(float x) {
        if (x == 1.0f) {
            return 1.0f;
        } else {
            return 1.0f - math.pow(2.0f, -10.0f * x);
        }
    }

    float easeInOutExpo(float x) {
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else if (x < 0.5f) {
            return math.pow(2.0f, 20.0f * x - 10.0f) / 2.0f;
        } else {
            return (2.0f - math.pow(2.0f, -20.0f * x + 10.0f)) / 2.0f;
        }
    }

    float easeInCirc(float x) {
        return 1.0f - math.sqrt(1.0f - math.pow(x, 2.0f));
    }

    float easeOutCirc(float x) {
        return math.sqrt(1.0f - math.pow(x - 1.0f, 2.0f));
    }

    float easeInOutCirc(float x) {
        if (x < 0.5f) {
            return (1.0f - math.sqrt(1.0f - math.pow(2.0f * x, 2.0f))) / 2.0f;
        } else {
            return (math.sqrt(1.0f - math.pow(-2.0f * x + 2.0f, 2.0f)) + 1.0f) / 2.0f;
        }
    }

    float easeInBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;
        return c3 * x * x * x - c1 * x * x;
    }

    float easeOutBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;
        return 1.0f + c3 * math.pow(x - 1.0f, 3.0f) + c1 * math.pow(x - 1.0f, 2.0f);
    }

    float easeInOutBack(float x) {
        enum c1 = 1.70158f;
        enum c2 = c1 * 1.525f;
        if (x < 0.5f) {
            return (math.pow(2.0f * x, 2.0f) * ((c2 + 1.0f) * 2.0f * x - c2)) / 2.0f;
        } else {
            return (math.pow(2.0f * x - 2.0f, 2.0f) * ((c2 + 1.0f) * (x * 2.0f - 2.0f) + c2) + 2.0f) / 2.0f;
        }
    }

    float easeInElastic(float x) {
        enum c4 = (2.0f * math.PI) / 3.0f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else {
            return -math.pow(2.0f, 10.0f * x - 10.0f) * math.sin((x * 10.0f - 10.75f) * c4);
        }
    }

    float easeOutElastic(float x) {
        enum c4 = (2.0f * math.PI) / 3.0f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else {
            return math.pow(2.0f, -10.0f * x) * math.sin((x * 10.0f - 0.75f) * c4) + 1.0f;
        }
    }

    float easeInOutElastic(float x) {
        enum c5 = (2.0f * math.PI) / 4.5f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else if (x < 0.5f) {
            return -(math.pow(2.0f, 20.0f * x - 10.0f) * math.sin((20.0f * x - 11.125f) * c5)) / 2.0f;
        } else {
            return (math.pow(2.0f, -20.0f * x + 10.0f) * math.sin((20.0f * x - 11.125f) * c5)) / 2.0f + 1.0f;
        }
    }

    float easeInBounce(float x) {
        return 1.0f - easeOutBounce(1.0f - x);
    }

    float easeOutBounce(float x) {
        enum n1 = 7.5625f;
        enum d1 = 2.75f;
        if (x < 1.0f / d1) {
            return n1 * x * x;
        } else if (x < 2.0f / d1) {
            return n1 * (x -= 1.5f / d1) * x + 0.75f;
        } else if (x < 2.5f / d1) {
            float xm = x - 2.25f / d1;
            return n1 * xm * xm + 0.9375f;
        } else {
            float xm = x - 2.625f / d1;
            return n1 * xm * xm + 0.984375f;
        }
    }

    float easeInOutBounce(float x) {
        if (x < 0.5f) {
            return (1.0f - easeOutBounce(1.0f - 2.0f * x)) / 2.0f;
        } else {
            return (1.0f + easeOutBounce(2.0f * x - 1.0f)) / 2.0f;
        }
    }

    float moveTowards(float a, float b, float dt) {
        float c = a + dt;
        if (c >= b) {
            return b;
        }
        return c;
    }
}

unittest {
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

unittest {
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

unittest {
    enum duration = 0.3;

    auto walkAnim = KeyframeGroup(duration, &easeNearest, TweenMode.loop);
    walkAnim.appendEvenly(0, 1, 2, 2);

    float dt = duration / (walkAnim.keys.length - 1) + 0.001;
    assert(walkAnim.now == walkAnim.keys[0].value);
    foreach (i; 1 .. walkAnim.keys.length - 1) {
        assert(walkAnim.update(dt) == walkAnim.keys[i].value);
    }
}

unittest {
    enum key1 = Keyframe(1, 1);
    enum key2 = Keyframe(2, 2);
    enum key3 = Keyframe(3, 3);

    auto group = KeyframeGroup();

    group.append(key3);
    group.append(key2);
    group.append(key1);
    assert(group.keys.length == 3);
    assert(group.pop() == key3);
    assert(group.pop() == key2);
    assert(group.pop() == key1);
    assert(group.pop() == Keyframe());
    assert(group.keys.length == 0);

    group.appendEvenly(1, 2, 3, 4);
    assert(group.keys.length == 4);
    group.remove(1);
    assert(group.keys.length == 3);
    assert(group.keys[1].value == 3);
}
