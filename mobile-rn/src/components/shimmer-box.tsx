/**
 * Loading skeleton block with a sweeping shimmer highlight.
 * Parity with Flutter `shared/widgets/shimmer_box.dart` (1200ms ease-in-out loop).
 */

import { useEffect } from 'react';
import { StyleSheet, View, type DimensionValue } from 'react-native';
import Animated, {
  Easing,
  useAnimatedProps,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { Colors } from '@/constants/theme';

const AnimatedRect = Animated.createAnimatedComponent(Rect);

/** Lighter highlight band — Flutter `shimmer_box.dart` line 58 (`0xFFF0F0F5`). */
const HIGHLIGHT_COLOR = '#F0F0F5';

type Props = {
  height: number;
  width?: DimensionValue;
  borderRadius?: number;
};

export function ShimmerBox({ height, width = '100%', borderRadius = 8 }: Props) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: 1200, easing: Easing.inOut(Easing.ease) }),
      -1,
      false,
    );
  }, [progress]);

  const animatedProps = useAnimatedProps(() => ({
    x: `${-150 + progress.value * 300}%`,
  }));

  return (
    <View style={[styles.container, { height, width, borderRadius }]}>
      <Svg width="100%" height="100%" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="shimmer" x1="0" y1="0" x2="1" y2="0">
            <Stop offset="0" stopColor={Colors.divider} />
            <Stop offset="0.5" stopColor={HIGHLIGHT_COLOR} />
            <Stop offset="1" stopColor={Colors.divider} />
          </LinearGradient>
        </Defs>
        <AnimatedRect
          animatedProps={animatedProps}
          y="0"
          width="300%"
          height="100%"
          fill="url(#shimmer)"
        />
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
    backgroundColor: Colors.divider,
  },
});
