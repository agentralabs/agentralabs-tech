import React from "react";
import { useCurrentFrame, interpolate, useVideoConfig } from "remotion";
import { COLORS, baseStyle } from "../styles";
import { DotGrid } from "./DotGrid";
import { SisterCard } from "./SisterCard";

const SISTERS = [
  {
    name: "AgenticMemory",
    format: ".amem",
    desc: "Persistent cognitive graph — facts, decisions, reasoning chains",
  },
  {
    name: "AgenticVision",
    format: ".avis",
    desc: "Visual memory — CLIP embeddings, similarity search, visual diff",
  },
  {
    name: "AgenticCodebase",
    format: ".acb",
    desc: "Semantic code intelligence — concept graphs, impact analysis",
  },
  {
    name: "AgenticIdentity",
    format: ".aid",
    desc: "Cryptographic identity — Ed25519 anchors, signed receipts",
  },
  {
    name: "AgenticTime",
    format: ".atime",
    desc: "Temporal reasoning — deadlines, PERT estimation, decay models",
  },
  {
    name: "AgenticContract",
    format: ".acon",
    desc: "Policy governance — risk limits, approvals, self-healing rules",
  },
  {
    name: "AgenticComm",
    format: ".acomm",
    desc: "Structured messaging — channels, pub/sub, acknowledgments",
  },
];

export const SceneSisters: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fadeOut = interpolate(frame, [180, 210], [1, 0], {
    extrapolateRight: "clamp",
  });

  const headerOpacity = interpolate(frame, [5, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const counterValue = interpolate(frame, [10, 80], [0, 7], {
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ ...baseStyle, opacity: fadeIn * fadeOut }}>
      <DotGrid opacity={0.15} />

      {/* Section header */}
      <div
        style={{
          position: "absolute",
          top: 60,
          left: 0,
          width: "100%",
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 20,
          opacity: headerOpacity,
        }}
      >
        <div
          style={{
            width: 80,
            height: 2,
            backgroundColor: COLORS.accent,
          }}
        />
        <div
          style={{
            fontSize: 14,
            letterSpacing: "0.3em",
            color: COLORS.muted,
            textTransform: "uppercase",
          }}
        >
          SEVEN OPEN-SOURCE SYSTEMS
        </div>
        <div
          style={{
            width: 80,
            height: 2,
            backgroundColor: COLORS.accent,
          }}
        />
      </div>

      {/* Large counter */}
      <div
        style={{
          position: "absolute",
          top: 100,
          right: 120,
          fontSize: 200,
          fontWeight: 700,
          color: COLORS.accent,
          opacity: 0.08,
          lineHeight: 1,
        }}
      >
        {Math.floor(counterValue)}
      </div>

      {/* Sister cards */}
      {SISTERS.map((sister, i) => (
        <SisterCard
          key={sister.name}
          name={sister.name}
          fileFormat={sister.format}
          description={sister.desc}
          index={i}
          startFrame={15}
          fps={fps}
        />
      ))}

      {/* Bottom tagline */}
      <div
        style={{
          position: "absolute",
          bottom: 60,
          left: 0,
          width: "100%",
          textAlign: "center",
          opacity: interpolate(frame, [100, 115], [0, 1], {
            extrapolateRight: "clamp",
          }),
        }}
      >
        <span
          style={{
            fontSize: 20,
            letterSpacing: "0.15em",
            color: COLORS.fg,
          }}
        >
          Seven file formats.{" "}
          <span style={{ color: COLORS.accent, fontWeight: 700 }}>
            Forever yours.
          </span>
        </span>
      </div>
    </div>
  );
};
