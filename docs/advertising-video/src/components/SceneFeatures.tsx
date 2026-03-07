import React from "react";
import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";

const FEATURES = [
  { stat: "MCP", label: "NATIVE PROTOCOL", desc: "Works with any MCP-compatible client" },
  { stat: "MIT", label: "OPEN SOURCE", desc: "Free forever. No vendor lock-in." },
  { stat: "20yr", label: "PERSISTENCE", desc: "Cognitive memory that outlasts any model" },
  { stat: "Ed25519", label: "CRYPTOGRAPHIC", desc: "Every agent action signed and verified" },
];

export const SceneFeatures: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fadeOut = interpolate(frame, [120, 150], [1, 0], {
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ ...baseStyle, opacity: fadeIn * fadeOut }}>
      <DotGrid opacity={0.2} />

      {/* Header */}
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
            backgroundColor: COLORS.accent,
          }}
        />
        <span
          style={{
            fontSize: 12,
            color: COLORS.muted,
            letterSpacing: "0.3em",
            textTransform: "uppercase",
          }}
        >
          WHY AGENTRA
        </span>
      </div>

      <div
        style={{
          position: "absolute",
          top: 140,
          left: 100,
          right: 100,
          fontSize: 36,
          fontWeight: 700,
          letterSpacing: "0.05em",
        }}
      >
        The model is commodity.{" "}
        <span style={{ color: COLORS.accent }}>The files are value.</span>
      </div>

      {/* Feature cards grid */}
      <div
        style={{
          display: "flex",
          gap: 32,
          marginTop: 60,
          zIndex: 5,
        }}
      >
        {FEATURES.map((feature, i) => {
          const delay = 20 + i * 12;
          const cardScale = spring({
            frame: Math.max(0, frame - delay),
            fps,
            config: { damping: 12, stiffness: 100 },
          });
          const cardOpacity = interpolate(
            frame,
            [delay, delay + 10],
            [0, 1],
            { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
          );

          return (
            <div
              key={feature.stat}
              style={{
                width: 380,
                border: `2px solid ${COLORS.border}`,
                padding: "40px 32px",
                opacity: cardOpacity,
                transform: `scale(${cardScale})`,
                display: "flex",
                flexDirection: "column",
                gap: 12,
              }}
            >
              <div
                style={{
                  fontSize: 48,
                  fontWeight: 700,
                  color: COLORS.accent,
                  letterSpacing: "0.05em",
                }}
              >
                {feature.stat}
              </div>
              <div
                style={{
                  fontSize: 13,
                  fontWeight: 700,
                  letterSpacing: "0.2em",
                  textTransform: "uppercase",
                  color: COLORS.fg,
                }}
              >
                {feature.label}
              </div>
              <div
                style={{
                  fontSize: 14,
                  color: COLORS.muted,
                  letterSpacing: "0.05em",
                }}
              >
                {feature.desc}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
