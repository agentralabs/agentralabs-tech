import React from "react";
import { useCurrentFrame } from "remotion";
import { COLORS } from "../styles";

export const ScanLine: React.FC = () => {
  const frame = useCurrentFrame();
  const y = (frame * 3) % 1080;

  return (
    <div
      style={{
        position: "absolute",
        top: y,
        left: 0,
        width: "100%",
        height: 2,
        background: `linear-gradient(90deg, transparent 0%, ${COLORS.accent}44 30%, ${COLORS.accent}88 50%, ${COLORS.accent}44 70%, transparent 100%)`,
        pointerEvents: "none",
        zIndex: 10,
      }}
    />
  );
};
