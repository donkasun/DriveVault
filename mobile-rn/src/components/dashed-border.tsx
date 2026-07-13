/**
 * Dashed rounded-rectangle border container. Parity with Flutter
 * `shared/widgets/dashed_border.dart` (`DashedBorderPainter`).
 *
 * Wraps `children` and paints a dashed border over them using an absolutely
 * positioned SVG rect sized to the measured layout.
 */

import { useState } from 'react';
import { StyleSheet, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Rect } from 'react-native-svg';

import { Colors } from '@/constants/theme';

type Props = {
  children?: React.ReactNode;
  color?: string;
  radius?: number;
  strokeWidth?: number;
  dashLength?: number;
  gapLength?: number;
  style?: React.ComponentProps<typeof View>['style'];
};

export function DashedBorder({
  children,
  color = Colors.dashedBorder,
  radius = 18,
  strokeWidth = 1.5,
  dashLength = 6,
  gapLength = 4,
  style,
}: Props) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  const onLayout = (event: LayoutChangeEvent) => {
    const { width, height } = event.nativeEvent.layout;
    setSize({ width, height });
  };

  return (
    <View style={style} onLayout={onLayout}>
      {size.width > 0 && size.height > 0 ? (
        <Svg
          width={size.width}
          height={size.height}
          style={StyleSheet.absoluteFill}
          pointerEvents="none"
        >
          <Rect
            x={strokeWidth / 2}
            y={strokeWidth / 2}
            width={Math.max(size.width - strokeWidth, 0)}
            height={Math.max(size.height - strokeWidth, 0)}
            rx={radius}
            ry={radius}
            fill="none"
            stroke={color}
            strokeWidth={strokeWidth}
            strokeDasharray={`${dashLength},${gapLength}`}
          />
        </Svg>
      ) : null}
      {children}
    </View>
  );
}
