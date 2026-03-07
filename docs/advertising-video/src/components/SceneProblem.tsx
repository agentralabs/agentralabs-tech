import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";
import { TypewriterText } from "./TypewriterText";

export const SceneProblem: React.FC = () => {
  const frame = useCurrentFrame();

  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateRight: "clamp",
  });

  const strikeProgress = interpolate(frame, [70, 85], [0, 100], {
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ ...baseStyle, opacity: fadeIn * fadeOut }}>
      <DotGrid opacity={0.2} />

      {/* Blinking orange dot */}
      <div
        style={{
          position: "absolute",
          top: 80,
          left: 100,
          display: "flex",
          alignItems: "center",
          gap: 12,
        }}
      >
        <div
          style={{
            width: 8,
            height: 8,
            borderRadius: "50%",
            backgroundColor: COLORS.accent,
            opacity: frame % 20 < 12 ? 1 : 0.2,
          }}
        />
        <span
          style={{
            fontSize: 12,
            color: COLORS.muted,
            letterSpacing: "0.2em",
            textTransform: "uppercase",
          }}
        >
          THE PROBLEM
        </span>
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 40,
          zIndex: 5,
        }}
      >
        <TypewriterText
          text="Your AI forgets you exist."
          startFrame={10}
          fontSize={64}
          speed={2}
        />

        {/* Fragmented memory visualization */}
        <div
          style={{
            display: "flex",
            gap: 8,
            marginTop: 20,
            opacity: interpolate(frame, [50, 60], [0, 1], {
              extrapolateRight: "clamp",
            }),
          }}
        >
          {["context", "memory", "identity", "history", "decisions"].map(
            (word, i) => {
              const fragOpacity = interpolate(
                frame,
                [55 + i * 4, 65 + i * 4, 75 + i * 3, 85 + i * 3],
                [0, 0.8, 0.8, 0.15],
                { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
              );
              return (
                <div
                  key={word}
                  style={{
                    border: `1px solid ${COLORS.border}`,
                    padding: "8px 16px",
                    fontSize: 13,
                    color: COLORS.muted,
                    opacity: fragOpacity,
                    letterSpacing: "0.1em",
                    textTransform: "uppercase",
                    textDecoration:
                      strikeProgress > i * 20 ? "line-through" : "none",
                    textDecorationColor: COLORS.accent,
                  }}
                >
                  {word}
                </div>
              );
            }
          )}
        </div>

        <div
          style={{
            fontSize: 16,
            color: COLORS.muted,
            opacity: interpolate(frame, [85, 95], [0, 1], {
              extrapolateRight: "clamp",
            }),
            letterSpacing: "0.1em",
          }}
        >
          Every session starts from zero.
        </div>
      </div>
    </div>
  );
};
