import { CSSProperties } from "react";

export const COLORS = {
  bg: "#0F0F0F",
  fg: "#F2F1EA",
  accent: "#ea580c",
  muted: "#999999",
  border: "#404040",
  dotGrid: "#1a1a1a",
} as const;

export const baseStyle: CSSProperties = {
  backgroundColor: COLORS.bg,
  color: COLORS.fg,
  fontFamily: "'JetBrains Mono', 'Courier New', monospace",
  width: "100%",
  height: "100%",
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  overflow: "hidden",
  position: "relative",
};
