import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { COLORS } from "../styles";

interface TypewriterTextProps {
  text: string;
  startFrame: number;
  fontSize?: number;
  color?: string;
  speed?: number;
}

export const TypewriterText: React.FC<TypewriterTextProps> = ({
  text,
  startFrame,
  fontSize = 48,
  color = COLORS.fg,
  speed = 1.5,
}) => {
  const frame = useCurrentFrame();
  const relFrame = frame - startFrame;

  if (relFrame < 0) return null;

  const typingDuration = text.length * speed;
  const charsToShow = Math.min(
    Math.floor(relFrame / speed),
    text.length
  );

  const cursorVisible = relFrame % 16 < 10;
  const showCursor = charsToShow < text.length || (relFrame - typingDuration) < 30;

  const opacity = interpolate(relFrame, [0, 3], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        fontSize,
        fontWeight: 400,
        color,
        opacity,
        whiteSpace: "nowrap",
      }}
    >
      {text.slice(0, charsToShow)}
      {showCursor && (
        <span
          style={{
            color: COLORS.accent,
            opacity: cursorVisible ? 1 : 0,
          }}
        >
          |
        </span>
      )}
    </div>
  );
};
