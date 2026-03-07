import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { COLORS } from "../styles";

interface GlitchTextProps {
  text: string;
  startFrame: number;
  fontSize?: number;
  color?: string;
  glitchIntensity?: number;
}

export const GlitchText: React.FC<GlitchTextProps> = ({
  text,
  startFrame,
  fontSize = 80,
  color = COLORS.fg,
  glitchIntensity = 1,
}) => {
  const frame = useCurrentFrame();
  const relFrame = frame - startFrame;

  if (relFrame < 0) return null;

  const revealProgress = interpolate(relFrame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });

  const charsToShow = Math.floor(revealProgress * text.length);

  const glitchActive = relFrame < 25 && relFrame % 3 === 0;
  const offsetX = glitchActive
    ? (Math.sin(relFrame * 13) * 4 * glitchIntensity)
    : 0;
  const offsetY = glitchActive
    ? (Math.cos(relFrame * 7) * 2 * glitchIntensity)
    : 0;

  const opacity = interpolate(relFrame, [0, 5], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ position: "relative", display: "inline-block" }}>
      {glitchActive && (
        <>
          <div
            style={{
              position: "absolute",
              fontSize,
              fontWeight: 700,
              letterSpacing: "0.15em",
              color: COLORS.accent,
              opacity: 0.5,
              transform: `translate(${offsetX + 3}px, ${offsetY - 2}px)`,
              whiteSpace: "nowrap",
            }}
          >
            {text.slice(0, charsToShow)}
          </div>
          <div
            style={{
              position: "absolute",
              fontSize,
              fontWeight: 700,
              letterSpacing: "0.15em",
              color: "#3b82f6",
              opacity: 0.3,
              transform: `translate(${-offsetX - 2}px, ${-offsetY + 1}px)`,
              whiteSpace: "nowrap",
            }}
          >
            {text.slice(0, charsToShow)}
          </div>
        </>
      )}
      <div
        style={{
          fontSize,
          fontWeight: 700,
          letterSpacing: "0.15em",
          color,
          opacity,
          transform: `translate(${offsetX * 0.5}px, ${offsetY * 0.5}px)`,
          whiteSpace: "nowrap",
        }}
      >
        {text.slice(0, charsToShow)}
        {charsToShow < text.length && (
          <span style={{ color: COLORS.accent }}>_</span>
        )}
      </div>
    </div>
  );
};
