import React from "react";
import { CSSProperties } from "react";
import { COLORS } from "../styles";

export const DotGrid: React.FC<{ opacity?: number }> = ({ opacity = 0.4 }) => {
  const style: CSSProperties = {
    position: "absolute",
    inset: 0,
    opacity,
    backgroundImage: `radial-gradient(circle, ${COLORS.dotGrid} 1px, transparent 1px)`,
    backgroundSize: "24px 24px",
    pointerEvents: "none",
  };

  return <div style={style} />;
};
