import React from "react";
import { useCurrentFrame, interpolate, Sequence } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";
import { ScanLine } from "./ScanLine";
import { GlitchText } from "./GlitchText";

export const SceneIntro: React.FC = () => {
  const frame = useCurrentFrame();

  const lineWidth = interpolate(frame, [0, 30], [0, 600], {
    extrapolateRight: "clamp",
  });

  const subtitleOpacity = interpolate(frame, [50, 65], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ ...baseStyle, opacity: fadeOut }}>
      <DotGrid opacity={0.3} />
      <ScanLine />

      {/* Top accent line */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          width: "100%",
          height: 4,
          backgroundColor: COLORS.accent,
        }}
      />

      {/* Center content */}
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 24,
          zIndex: 5,
        }}
      >
        {/* Horizontal line above */}
        <div
          style={{
            width: lineWidth,
            height: 2,
            backgroundColor: COLORS.accent,
          }}
        />

        <GlitchText
          text="AGENTRA LABS"
          startFrame={5}
          fontSize={96}
          glitchIntensity={2}
        />

        {/* Horizontal line below */}
        <div
          style={{
            width: lineWidth,
            height: 2,
            backgroundColor: COLORS.accent,
          }}
        />

        <div
          style={{
            fontSize: 14,
            letterSpacing: "0.4em",
            color: COLORS.muted,
            opacity: subtitleOpacity,
            textTransform: "uppercase",
          }}
        >
          OPEN SOURCE AGENTIC LAB
        </div>
      </div>

      {/* Corner markers */}
      {[
        { top: 40, left: 40 },
        { top: 40, right: 40 },
        { bottom: 40, left: 40 },
        { bottom: 40, right: 40 },
      ].map((pos, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            ...pos,
            width: 20,
            height: 20,
            borderTop: i < 2 ? `2px solid ${COLORS.border}` : "none",
            borderBottom: i >= 2 ? `2px solid ${COLORS.border}` : "none",
            borderLeft: i % 2 === 0 ? `2px solid ${COLORS.border}` : "none",
            borderRight: i % 2 === 1 ? `2px solid ${COLORS.border}` : "none",
            opacity: subtitleOpacity,
          } as React.CSSProperties}
        />
      ))}
    </div>
  );
};
