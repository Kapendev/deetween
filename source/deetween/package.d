// Copyright 2023 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: Apache-2.0

// NOTE: Maybe add splines.

module deetween;

import math = core.math;
import expo = std.math.exponential;

private enum PI = 3.141592f;

/// A representation of an easing function.
alias EasingFunc = float function(float x) pure nothrow @nogc @safe;

/// A tween mode describes how an animation should update.
enum TweenMode {
    bomb, /// It stops updating when it reaches the beginning or end of the animation.
    loop, /// It returns to the beginning or end of the animation when it reaches the beginning or end of the animation.
    yoyo, /// It reverses the given delta when it reaches the beginning or end of the animation.
}

/// A tween handles the transition from one value to another value based on a transition duration.
struct Tween {
pure nothrow @nogc @safe:

    EasingFunc f = &easeLinear; /// The function used to ease from the first to the last value.
    TweenMode mode = TweenMode.bomb; /// The mode of the animation.
    float a = 0.0f; /// The first animation value.
    float b = 0.0f; /// The last animation value.
    float time = 0.0f; /// The current time of the animation.
    float duration = 0.0f; /// The duration of the animation.
    bool isYoyoing; /// Controls if the delta given to the update function is reversed.

    /// Creates a new tween.
    this(float a, float b, float duration, TweenMode mode, EasingFunc f = &easeLinear) {
        this.a = a;
        this.b = b;
        this.duration = duration;
        this.f = f;
        this.mode = mode;
    }

    /// Returns true if the animation has started.
    /// This function makes sense when the tween mode is set to bomb.
    bool hasStarted() {
        return time > 0.0f;
    }

    /// Returns true if the animation has finished.
    /// This function makes sense when the tween mode is set to bomb.
    bool hasFinished() {
        return time >= duration;
    }

    /// Returns the current animation progress.
    /// The progress is between 0.0 and 1.0.
    float progress() {
        if (duration != 0.0f) {
            return clamp(time / duration, 0.0f, 1.0f);
        }
        return 0.0f;
    }

    /// Sets the current animation progress to a specific value.
    /// The progress is between 0.0 and 1.0.
    void progress(float value) {
        time = clamp(value * duration, 0.0f, 1.0f);
    }

    /// Returns the current animation value.
    /// The value is between the first and the last animation value.
    float now() {
        if (time <= 0.0f) {
            return a;
        } else if (time >= duration) {
            return b;
        } else {
            return ease(a, b, progress, f);
        }
    }

    /// Sets the current animation time to a specific value and returns the current animation value.
    float elapsedTime(float time) {
        final switch (mode) {
        case TweenMode.bomb:
            this.time = clamp(time, 0.0f, duration);
            return now;
        case TweenMode.loop:
            this.time = loopClamp(time, 0.0f, duration);
            return now;
        case TweenMode.yoyo:
            if (time < 0.0f) {
                isYoyoing = false;
            } else if (time > duration) {
                isYoyoing = true;
            }
            this.time = clamp(time, 0.0f, duration);
            return now;
        }
    }

    /// Updates the current animation time by the given delta and returns the current animation value.
    float update(float dt) {
        if (isYoyoing) {
            return elapsedTime(time - dt);
        } else {
            return elapsedTime(time + dt);
        }
    }

    /// Resets the current animation time.
    void reset() {
        time = 0.0f;
    }
}

/// A keyframe is a data type that has a value and a time.
struct Keyframe {
pure nothrow @nogc @safe:

    float value = 0.0f; /// The current value.
    float time = 0.0f; /// The current time.

    /// Creates a new keyframe.
    this(float value, float time) {
        this.value = value;
        this.time = time;
    }
}

/// A keyframe group handles the transition from one keyframe to another keyframe.
struct KeyframeGroup {
pure nothrow @safe:

    enum defaultCapacity = 16;

    Keyframe[] keys; /// The keyframes of the animation.
    EasingFunc f = &easeLinear; /// The function used to ease from one keyframe to another keyframe.
    TweenMode mode = TweenMode.bomb; /// The mode of the animation.
    float time = 0.0f; /// The current time of the animation.
    float duration = 0.0f; /// The duration of the animation
    bool isYoyoing; /// Controls if the delta given to the update function is reversed.

    /// Creates a new keyframe group.
    this(float duration, TweenMode mode, EasingFunc f = &easeLinear) {
        reserve(keys, defaultCapacity);
        this.duration = duration;
        this.f = f;
        this.mode = mode;
    }

    /// Returns true if the animation has started.
    /// This function makes sense when the tween mode is set to bomb.
    @nogc
    bool hasStarted() {
        return time > 0.0f;
    }

    /// Returns true if the animation has finished.
    /// This function makes sense when the tween mode is set to bomb.
    @nogc
    bool hasFinished() {
        return time >= duration;
    }

    /// Returns the current animation progress.
    /// The progress is between 0.0 and 1.0.
    @nogc
    float progress() {
        if (duration != 0.0f) {
            return clamp(time / duration, 0.0f, 1.0f);
        }
        return 0.0f;
    }

    /// Sets the current animation progress to a specific value.
    /// The progress is between 0.0 and 1.0.
    @nogc
    void progress(float value) {
        time = clamp(value * duration, 0.0f, 1.0f);
    }

    /// Returns the current animation value.
    /// The value is between the current keyframe and the next keyframe.
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

    /// Sets the current animation time to a specific value and returns the current animation value.
    @nogc
    float elapsedTime(float time) {
        final switch (mode) {
        case TweenMode.bomb:
            this.time = clamp(time, 0.0f, duration);
            return now;
        case TweenMode.loop:
            this.time = loopClamp(time, 0.0f, duration);
            return now;
        case TweenMode.yoyo:
            if (time < 0.0f) {
                isYoyoing = false;
            } else if (time > duration) {
                isYoyoing = true;
            }
            this.time = clamp(time, 0.0f, duration);
            return now;
        }
    }

    /// Updates the current animation time by the given delta and returns the current animation value.
    @nogc
    float update(float dt) {
        if (isYoyoing) {
            return elapsedTime(time - dt);
        } else {
            return elapsedTime(time + dt);
        }
    }

    /// Resets the current animation time.
    @nogc
    void reset() {
        time = 0.0f;
    }

    /// Returns the keyframe count of the animation.
    @nogc
    size_t length() {
        return keys.length;
    }

    /// Appends the keyframe to the animation.
    void append(Keyframe[] items...) {
        foreach (item; items) {
            if (keys.length == 0 || keys[$ - 1].time <= item.time) {
                keys ~= item;
            } else {
                keys ~= item;
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
    }

    /// A helper function for appending many keyframes evenly to the animation.
    void appendEvenly(float[] values...) {
        foreach (i; 0 .. values.length) {
            float t;
            if (i == 0) {
                t = 0.0f;
            } else if (i == values.length - 1) {
                t = duration;
            } else {
                t = duration * (cast(float)(i) / (values.length - 1));
            }
            append(Keyframe(values[i], t));
        }
    }

    /// Removes a keyframe from the animation.
    @nogc
    void remove(size_t idx) {
        foreach (i; 0 .. keys.length - 1) {
            keys[i] = keys[i + 1];
        }
        keys = keys[0 .. $ - 1];
    }

    /// Removes all keyframes from the animation.
    @nogc
    void clear() {
        keys.length = 0;
    }
}

/// A value sequence handles the transition from one value to another value based on a value duration.
struct ValueSequence {
pure nothrow @nogc @safe:

    TweenMode mode; /// The mode of the animation.
    int a; /// The first animation value.
    int b; /// The last animation value.
    int value; /// The current animation value.
    float valueTime = 0.0f; /// The current time of the current value.
    float valueDuration = 0.0f; /// The duration of a value.
    bool isYoyoing; /// Controls if the delta given to the update function is reversed.

    /// Creates a new value sequence.
    this(int a, int b, float valueDuration, TweenMode mode) {
        this.a = a;
        this.b = b;
        this.value = a;
        this.valueDuration = valueDuration;
        this.mode = mode;
    }

    /// Returns true if the animation has started.
    /// This function makes sense when the tween mode is set to bomb.
    bool hasStarted() {
        return value > a;
    }

    /// Returns true if the animation has finished.
    /// This function makes sense when the tween mode is set to bomb.
    bool hasFinished() {
        return value >= b;
    }

    /// Returns the current animation value.
    /// The value is between the first and the last animation value.
    int now() {
        if (value < a) {
            return a;
        } else if (value > b) {
            return b;
        } else {
            return value;
        }
    }

    /// Updates the current time of the current value by the given delta and returns the current animation value.
    int update(float dt) {
        if (isYoyoing) {
            valueTime -= dt;
        } else {
            valueTime += dt;
        }
        final switch (mode) {
        case TweenMode.bomb:
            while (valueTime < 0.0f) {
                if (value > a) {
                    value -= 1;
                    valueTime += valueDuration;
                } else {
                    valueTime = 0.0f;
                }
            }
            while (valueTime > valueDuration) {
                if (value < b) {
                    value += 1;
                    valueTime -= valueDuration;
                } else {
                    valueTime = valueDuration;
                }
            }
            return now;
        case TweenMode.loop:
            while (valueTime < 0.0f) {
                if (value > a) {
                    value -= 1;
                } else {
                    value = b;
                }
                valueTime += valueDuration;
            }
            while (valueTime > valueDuration) {
                if (value < b) {
                    value += 1;
                } else {
                    value = a;
                }
                valueTime -= valueDuration;
            }
            return now;
        case TweenMode.yoyo:
            while (valueTime < 0.0f) {
                if (value > a) {
                    value -= 1;
                    valueTime += valueDuration;
                } else {
                    valueTime = 0.0f;
                    isYoyoing = false;
                }
            }
            while (valueTime > valueDuration) {
                if (value < b) {
                    value += 1;
                    valueTime -= valueDuration;
                } else {
                    valueTime = valueDuration;
                    isYoyoing = true;
                }
            }
            return now;
        }
    }

    /// Resets the current animation value.
    void reset() {
        value = a;
        valueTime = 0.0f;
    }
}

pure nothrow @nogc @safe {
    /// An easing function.
    float easeNearest(float x) {
        return 0.0f;
    }

    /// An easing function.
    float easeLinear(float x) {
        return x;
    }

    /// An easing function.
    float easeInSine(float x) {
        return 1.0f - math.cos((x * PI) / 2.0f);
    }

    /// An easing function.
    float easeOutSine(float x) {
        return math.sin((x * PI) / 2.0f);
    }

    /// An easing function.
    float easeInOutSine(float x) {
        return -(math.cos(PI * x) - 1.0f) / 2.0f;
    }

    /// An easing function.
    float easeInQuad(float x) {
        return x * x;
    }

    /// An easing function.
    float easeOutQuad(float x) {
        return 1.0f - (1.0f - x) * (1.0f - x);
    }

    /// An easing function.
    float easeInOutQuad(float x) {
        if (x < 0.5f) {
            return 2.0f * x * x;
        } else {
            return 1.0f - expo.pow(-2.0f * x + 2.0f, 2.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInCubic(float x) {
        return x * x * x;
    }

    /// An easing function.
    float easeOutCubic(float x) {
        return 1.0f - expo.pow(1.0f - x, 3.0f);
    }

    /// An easing function.
    float easeInOutCubic(float x) {
        if (x < 0.5f) {
            return 4.0f * x * x * x;
        } else {
            return 1.0f - expo.pow(-2.0f * x + 2.0f, 3.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInQuart(float x) {
        return x * x * x * x;
    }

    /// An easing function.
    float easeOutQuart(float x) {
        return 1.0f - expo.pow(1.0f - x, 4.0f);
    }

    /// An easing function.
    float easeInOutQuart(float x) {
        if (x < 0.5f) {
            return 8.0f * x * x * x * x;
        } else {
            return 1.0f - expo.pow(-2.0f * x + 2.0f, 4.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInQuint(float x) {
        return x * x * x * x * x;
    }

    /// An easing function.
    float easeOutQuint(float x) {
        return 1.0f - expo.pow(1.0f - x, 5.0f);
    }

    /// An easing function.
    float easeInOutQuint(float x) {
        if (x < 0.5f) {
            return 16.0f * x * x * x * x * x;
        } else {
            return 1.0f - expo.pow(-2.0f * x + 2.0f, 5.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInExpo(float x) {
        if (x == 0.0f) {
            return 0.0f;
        } else {
            return expo.pow(2.0f, 10.0f * x - 10.0f);
        }
    }

    /// An easing function.
    float easeOutExpo(float x) {
        if (x == 1.0f) {
            return 1.0f;
        } else {
            return 1.0f - expo.pow(2.0f, -10.0f * x);
        }
    }

    /// An easing function.
    float easeInOutExpo(float x) {
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else if (x < 0.5f) {
            return expo.pow(2.0f, 20.0f * x - 10.0f) / 2.0f;
        } else {
            return (2.0f - expo.pow(2.0f, -20.0f * x + 10.0f)) / 2.0f;
        }
    }

    /// An easing function.
    float easeInCirc(float x) {
        return 1.0f - math.sqrt(1.0f - expo.pow(x, 2.0f));
    }

    /// An easing function.
    float easeOutCirc(float x) {
        return math.sqrt(1.0f - expo.pow(x - 1.0f, 2.0f));
    }

    /// An easing function.
    float easeInOutCirc(float x) {
        if (x < 0.5f) {
            return (1.0f - math.sqrt(1.0f - expo.pow(2.0f * x, 2.0f))) / 2.0f;
        } else {
            return (math.sqrt(1.0f - expo.pow(-2.0f * x + 2.0f, 2.0f)) + 1.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;
        return c3 * x * x * x - c1 * x * x;
    }

    /// An easing function.
    float easeOutBack(float x) {
        enum c1 = 1.70158f;
        enum c3 = c1 + 1.0f;
        return 1.0f + c3 * expo.pow(x - 1.0f, 3.0f) + c1 * expo.pow(x - 1.0f, 2.0f);
    }

    /// An easing function.
    float easeInOutBack(float x) {
        enum c1 = 1.70158f;
        enum c2 = c1 * 1.525f;
        if (x < 0.5f) {
            return (expo.pow(2.0f * x, 2.0f) * ((c2 + 1.0f) * 2.0f * x - c2)) / 2.0f;
        } else {
            return (expo.pow(2.0f * x - 2.0f, 2.0f) * ((c2 + 1.0f) * (x * 2.0f - 2.0f) + c2) + 2.0f) / 2.0f;
        }
    }

    /// An easing function.
    float easeInElastic(float x) {
        enum c4 = (2.0f * PI) / 3.0f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else {
            return -expo.pow(2.0f, 10.0f * x - 10.0f) * math.sin((x * 10.0f - 10.75f) * c4);
        }
    }

    /// An easing function.
    float easeOutElastic(float x) {
        enum c4 = (2.0f * PI) / 3.0f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else {
            return expo.pow(2.0f, -10.0f * x) * math.sin((x * 10.0f - 0.75f) * c4) + 1.0f;
        }
    }

    /// An easing function.
    float easeInOutElastic(float x) {
        enum c5 = (2.0f * PI) / 4.5f;
        if (x == 0.0f) {
            return 0.0f;
        } else if (x == 1.0f) {
            return 1.0f;
        } else if (x < 0.5f) {
            return -(expo.pow(2.0f, 20.0f * x - 10.0f) * math.sin((20.0f * x - 11.125f) * c5)) / 2.0f;
        } else {
            return (expo.pow(2.0f, -20.0f * x + 10.0f) * math.sin((20.0f * x - 11.125f) * c5)) / 2.0f + 1.0f;
        }
    }

    /// An easing function.
    float easeInBounce(float x) {
        return 1.0f - easeOutBounce(1.0f - x);
    }

    /// An easing function.
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

    /// An easing function.
    float easeInOutBounce(float x) {
        if (x < 0.5f) {
            return (1.0f - easeOutBounce(1.0f - 2.0f * x)) / 2.0f;
        } else {
            return (1.0f + easeOutBounce(2.0f * x - 1.0f)) / 2.0f;
        }
    }

    /// Interpolates linearly between a and b by weight.
    /// The weight should be between 0.0 and 1.0, but this is not mandatory.
    float lerp(float a, float b, float weight) {
        return a + (b - a) * weight;
    }

    /// Interpolates between a and b by weight by using an easing function.
    /// The weight should be between 0.0 and 1.0, but this is not mandatory.
    float ease(float a, float b, float weight, EasingFunc f) {
        return a + (b - a) * f(weight);
    }

    /// Interpolates between a and b with smoothing at the limits by weight.
    /// The weight should be between 0.0 and 1.0, but this is not mandatory.
    float smoothStep(float a, float b, float weight) {
        float v = weight * weight * (3.0f - 2.0f * weight);
        return (b * v) + (a * (1.0f - v));
    }

    /// Interpolates between a and b with smoothing at the limits by weight.
    /// The weight should be between 0.0 and 1.0, but this is not mandatory.
    float smootherStep(float a, float b, float weight) {
        float v = weight * weight * weight * (weight * (weight * 6.0f - 15.0f) + 10.0f);
        return (b * v) + (a * (1.0f - v));
    }

    /// Interpolates linearly between a and b by delta.
    float moveTowards(float a, float b, float dt) {
        if (abs(b - a) <= dt) {
            return b;
        }
        return a + sign(b - a) * dt;
    }

    /// Interpolates smoothly between a and b by delta by using a slowdown factor.
    float smoothDamp(float a, float b, float dt, float slowdown) {
        if (abs(b - a) <= dt) {
            return b;
        }
        return (((a + sign(b - a) * dt) * (slowdown - 1.0f)) + b) / slowdown;
    }

    private float abs(float x) {
        if (x < 0.0f) {
            return -x;
        } else {
            return x;
        }
    }

    private float sign(float x) {
        if (x < 0.0f) {
            return -1.0f;
        } else {
            return 1.0f;
        }
    }

    private float clamp(float x, float min, float max) {
        if (x < min) {
            return min;
        } else if (x > max) {
            return max;
        } else {
            return x;
        }
    }

    private float loopClamp(float x, float min, float max) {
        float result = x;
        while (result < min) {
            result += max;
        }
        while (result > max) {
            result -= max;
        }
        return result;
    }
}

unittest {
    const a = 9.0f;
    const b = 20.0f;
    const totalDuration = 1.0f;
    const dt = 0.001f;

    auto tween = Tween(a, b, totalDuration, TweenMode.bomb);

    assert(tween.now == a);
    while (!tween.hasFinished) {
        float value = tween.update(dt);
        assert(value >= a && value <= b);
    }
    assert(tween.now == b);
}

unittest {
    const a = 9.0f;
    const b = 20.0f;
    const totalDuration = 1.0f;
    const dt = 0.001f;

    auto group = KeyframeGroup(totalDuration, TweenMode.bomb);
    group.append(
        Keyframe(a, 0.0),
        Keyframe(b, totalDuration),
    );

    assert(group.now == a);
    while (!group.hasFinished) {
        float value = group.update(dt);
        assert(value >= a && value <= b);
    }
    assert(group.now == b);
}

unittest {
    const a = 9;
    const b = 20;
    const valueDuration = 0.1f;
    const dt = 0.001f;

    auto sequence = ValueSequence(a, b, valueDuration, TweenMode.bomb);

    assert(sequence.now == a);
    while (!sequence.hasFinished) {
        int value = sequence.update(dt);
        assert(value >= a && value <= b);
    }
    assert(sequence.now == b);
}

unittest {
    const a = 69;
    const b = 420;
    const totalDuration = 1.0f;

    auto anim1 = Tween(a, b, totalDuration, TweenMode.loop);
    auto anim2 = KeyframeGroup(totalDuration, TweenMode.loop);
    auto anim3 = ValueSequence(a, b, totalDuration / (b - a), TweenMode.loop);
    anim2.appendEvenly(a, b);

    assert(anim1.progress == 0.0f);
    assert(anim2.progress == 0.0f);

    assert(anim1.update(0.0f) == a);
    assert(anim2.update(0.0f) == a);
    assert(anim3.update(0.0f) == a);

    assert(anim1.update(totalDuration) == b);
    assert(anim2.update(totalDuration) == b);
    assert(anim3.update(totalDuration) == b);

    assert(anim1.progress == 1.0f);
    assert(anim2.progress == 1.0f);

    anim1.reset();
    anim2.reset();
    anim3.reset();

    assert(anim1.update(totalDuration + 0.1f) < b);
    assert(anim2.update(totalDuration + 0.1f) < b);
    assert(anim3.update(totalDuration + 0.1f) < b);
}

unittest {
    const a = 1;
    const b = 2;
    const c = 3;

    auto group = KeyframeGroup();
    group.appendEvenly(a, b, c);

    assert(group.keys.length == 3);
    assert(group.keys[0].value == a);
    group.remove(0);
    assert(group.keys.length == 2);
    assert(group.keys[0].value == b);
}
