import React from "react";
import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";
import { ScanLine } from "./ScanLine";

export const SceneCTA: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });

  const logoScale = spring({
    frame: Math.max(0, frame - 5),
    fps,
    config: { damping: 8, stiffness: 60 },
  });

  const urlOpacity = interpolate(frame, [40, 55], [0, 1], {
    extrapolateRight: "clamp",
  });

  const badgeOpacity = interpolate(frame, [60, 75], [0, 1], {
    extrapolateRight: "clamp",
  });

  const lineWidth = interpolate(frame, [10, 50], [0, 700], {
    extrapolateRight: "clamp",
  });

  // Pulsing glow on accent elements
  const glowPulse = Math.sin(frame * 0.1) * 0.3 + 0.7;

  return (
    <div style={{ ...baseStyle, opacity: fadeIn }}>
      <DotGrid opacity={0.25} />
      <ScanLine />

      {/* Top accent bar */}
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

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 32,
          zIndex: 5,
        }}
      >
        {/* Logo text */}
        <div
          style={{
            fontSize: 88,
            fontWeight: 700,
            letterSpacing: "0.15em",
            transform: `scale(${logoScale})`,
          }}
        >
          AGENTRA
        </div>

        {/* Divider */}
        <div
          style={{
            width: lineWidth,
            height: 2,
            backgroundColor: COLORS.accent,
          }}
        />

        {/* Tagline */}
        <div
          style={{
            fontSize: 22,
            letterSpacing: "0.2em",
            color: COLORS.fg,
            opacity: urlOpacity,
          }}
        >
          OPEN SOURCE AGENTIC INTELLIGENCE
        </div>

        {/* URL */}
        <div
          style={{
            fontSize: 28,
            color: COLORS.accent,
            fontWeight: 600,
            letterSpacing: "0.1em",
            opacity: urlOpacity,
          }}
        >
          agentralabs.tech
        </div>

        {/* Badges row */}
        <div
          style={{
            display: "flex",
            gap: 24,
            marginTop: 16,
            opacity: badgeOpacity,
          }}
        >
          {["MIT LICENSED", "MCP NATIVE", "FOREVER YOURS"].map((badge) => (
            <div
              key={badge}
              style={{
                border: `2px solid ${COLORS.accent}`,
                padding: "10px 24px",
                fontSize: 13,
                fontWeight: 700,
                letterSpacing: "0.2em",
                color: COLORS.accent,
                opacity: glowPulse,
              }}
            >
              {badge}
            </div>
          ))}
        </div>

        {/* GitHub CTA */}
        <div
          style={{
            marginTop: 24,
            display: "flex",
            alignItems: "center",
            gap: 16,
            opacity: badgeOpacity,
          }}
        >
          <div
            style={{
              backgroundColor: COLORS.accent,
              padding: "14px 40px",
              fontSize: 16,
              fontWeight: 700,
              letterSpacing: "0.15em",
              color: COLORS.bg,
            }}
          >
            STAR ON GITHUB
          </div>
          <span
            style={{
              fontSize: 14,
              color: COLORS.muted,
              letterSpacing: "0.1em",
            }}
          >
            github.com/agentralabs
          </span>
        </div>
      </div>

      {/* Bottom accent bar */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          width: "100%",
          height: 4,
          backgroundColor: COLORS.accent,
        }}
      />

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
            width: 24,
            height: 24,
            borderTop: i < 2 ? `2px solid ${COLORS.accent}` : "none",
            borderBottom: i >= 2 ? `2px solid ${COLORS.accent}` : "none",
            borderLeft: i % 2 === 0 ? `2px solid ${COLORS.accent}` : "none",
            borderRight: i % 2 === 1 ? `2px solid ${COLORS.accent}` : "none",
          } as React.CSSProperties}
        />
      ))}
    </div>
  );
};
