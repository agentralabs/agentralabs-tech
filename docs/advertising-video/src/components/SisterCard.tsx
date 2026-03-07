import React from "react";
import { useCurrentFrame, interpolate, spring } from "remotion";
import { COLORS } from "../styles";

interface SisterCardProps {
  name: string;
  fileFormat: string;
  description: string;
  index: number;
  startFrame: number;
  fps: number;
}

export const SisterCard: React.FC<SisterCardProps> = ({
  name,
  fileFormat,
  description,
  index,
  startFrame,
  fps,
}) => {
  const frame = useCurrentFrame();
  const delay = index * 8;
  const relFrame = frame - startFrame - delay;

  if (relFrame < -5) return null;

  const scale = spring({
    frame: Math.max(0, relFrame),
    fps,
    config: { damping: 12, stiffness: 100 },
  });

  const opacity = interpolate(Math.max(0, relFrame), [0, 10], [0, 1], {
    extrapolateRight: "clamp",
  });

  const translateY = interpolate(scale, [0, 1], [30, 0]);

  const isLeft = index < 4;
  const row = isLeft ? index : index - 4;

  return (
    <div
      style={{
        position: "absolute",
        left: isLeft ? 100 : 1020,
        top: 80 + row * 240,
        width: 800,
        opacity,
        transform: `translateY(${translateY}px) scale(${scale})`,
      }}
    >
      <div
        style={{
          border: `2px solid ${COLORS.border}`,
          padding: "20px 28px",
          display: "flex",
          alignItems: "center",
          gap: 20,
          background: `${COLORS.bg}ee`,
        }}
      >
        <div
          style={{
            width: 4,
            height: 60,
            backgroundColor: COLORS.accent,
            flexShrink: 0,
          }}
        />
        <div style={{ flex: 1 }}>
          <div
            style={{
              display: "flex",
              alignItems: "baseline",
              gap: 16,
              marginBottom: 6,
            }}
          >
            <span
              style={{
                fontSize: 22,
                fontWeight: 700,
                letterSpacing: "0.1em",
                textTransform: "uppercase",
              }}
            >
              {name}
            </span>
            <span
              style={{
                fontSize: 16,
                color: COLORS.accent,
                fontWeight: 600,
              }}
            >
              {fileFormat}
            </span>
          </div>
          <div
            style={{
              fontSize: 14,
              color: COLORS.muted,
              letterSpacing: "0.05em",
            }}
          >
            {description}
          </div>
        </div>
      </div>
    </div>
  );
};
