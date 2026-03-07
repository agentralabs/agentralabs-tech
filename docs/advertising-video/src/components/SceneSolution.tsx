import React from "react";
import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";
import { ScanLine } from "./ScanLine";

export const SceneSolution: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fadeOut = interpolate(frame, [130, 150], [1, 0], {
    extrapolateRight: "clamp",
  });

  const line1Opacity = interpolate(frame, [5, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const line2Opacity = interpolate(frame, [35, 45], [0, 1], {
    extrapolateRight: "clamp",
  });

  const taglineScale = spring({
    frame: Math.max(0, frame - 70),
    fps,
    config: { damping: 10, stiffness: 80 },
  });

  const taglineOpacity = interpolate(frame, [70, 80], [0, 1], {
    extrapolateRight: "clamp",
  });

  const words = ["REMEMBER.", "SEE.", "PROVE.", "UNDERSTAND."];

  return (
    <div style={{ ...baseStyle, opacity: fadeIn * fadeOut }}>
      <DotGrid opacity={0.2} />
      <ScanLine />

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 32,
          zIndex: 5,
        }}
      >
        {/* Line 1 */}
        <div
          style={{
            fontSize: 40,
            color: COLORS.fg,
            opacity: line1Opacity,
            letterSpacing: "0.05em",
          }}
        >
          Ours remembers for{" "}
          <span style={{ color: COLORS.accent, fontWeight: 700 }}>
            20 years
          </span>
          .
        </div>

        {/* Line 2 - file size context */}
        <div
          style={{
            fontSize: 18,
            color: COLORS.muted,
            opacity: line2Opacity,
            letterSpacing: "0.1em",
          }}
        >
          ~10-15 GB of cognitive history. Portable. Yours forever.
        </div>

        {/* Divider */}
        <div
          style={{
            width: interpolate(frame, [55, 70], [0, 400], {
              extrapolateRight: "clamp",
            }),
            height: 2,
            backgroundColor: COLORS.accent,
            marginTop: 20,
            marginBottom: 20,
          }}
        />

        {/* Tagline words */}
        <div
          style={{
            display: "flex",
            gap: 40,
            opacity: taglineOpacity,
            transform: `scale(${taglineScale})`,
          }}
        >
          {words.map((word, i) => {
            const wordDelay = 75 + i * 10;
            const wordOpacity = interpolate(
              frame,
              [wordDelay, wordDelay + 8],
              [0, 1],
              { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
            );
            const wordY = interpolate(
              frame,
              [wordDelay, wordDelay + 8],
              [20, 0],
              { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
            );

            return (
              <div
                key={word}
                style={{
                  fontSize: 52,
                  fontWeight: 700,
                  letterSpacing: "0.08em",
                  opacity: wordOpacity,
                  transform: `translateY(${wordY}px)`,
                  color: i === 3 ? COLORS.accent : COLORS.fg,
                }}
              >
                {word}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
