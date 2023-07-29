// Copyright 2023 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: Apache-2.0

// TODO: Add more easing functions.
// TODO: Add space keys even function thing.

module deetween;

import math = std.math;

alias EasingFunc = float function(float x) pure nothrow @nogc @safe;

enum TweenKind {
    linear,
    cubic,
    nearest,
}

enum TweenMode {
    bomb,
    loop,
    yoyo,
}

struct Tween {
pure nothrow @nogc @safe:

    float a;
    float b;
    float time;
    float duration;
    TweenKind kind;
    TweenMode mode;
    bool isYoyoing;

    this(float a, float b, float duration, TweenKind kind, TweenMode mode) {
        this.a = a;
        this.b = b;
        this.time = 0.0f;
        this.duration = duration;
        this.kind = kind;
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
            return ease(a, b, progress, toEasingFunc(kind));
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
}

struct Keyframe {
pure nothrow @nogc @safe:

    float value;
    float time;

    this(float value, float time) {
        this.value = value;
        this.time = time;
    }
}

struct KeyframeGroup {
pure nothrow @safe:

    enum defaultCapacity = 16;

    Keyframe[] keys;
    float time;
    float duration;
    TweenKind kind;
    TweenMode mode;
    bool isYoyoing;

    this(float duration, TweenKind kind, TweenMode mode) {
        reserve(keys, defaultCapacity);
        this.time = 0.0f;
        this.duration = duration;
        this.kind = kind;
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
                    return ease(a.value, b.value, weight, toEasingFunc(kind));
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

    // NOTE: Does not sort! Maybe change that?
    void append(Keyframe key) {
        keys ~= key;
    }

    @nogc
    void remove(size_t idx) {
        int i = 0;
        while (i + 1 < keys.length) {
            keys[i] = keys[i + 1];
        }
        keys = keys[0 .. $ - 1];
    }
}

pure nothrow @nogc @safe {
    EasingFunc toEasingFunc(TweenKind kind) {
        final switch (kind) {
        case TweenKind.linear:
            return &easeLinear;
        case TweenKind.cubic:
            return &easeInOutCubic;
        case TweenKind.nearest:
            return &easeNearest;
        }
    }

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
}

unittest {
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

unittest {
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
