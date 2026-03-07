import React from "react";
import { AbsoluteFill, useVideoConfig } from "remotion";
import { COLORS } from "../styles";

interface PlatformWrapperProps {
  children: React.ReactNode;
  sourceWidth?: number;
  sourceHeight?: number;
}

/**
 * Scales the 1920x1080 source content to fit different platform
 * dimensions while maintaining aspect ratio. Content is centered
 * and cropped to fill (cover mode).
 */
export const PlatformWrapper: React.FC<PlatformWrapperProps> = ({
  children,
  sourceWidth = 1920,
  sourceHeight = 1080,
}) => {
  const { width, height } = useVideoConfig();

  const scaleX = width / sourceWidth;
  const scaleY = height / sourceHeight;
  const scale = Math.max(scaleX, scaleY);

  const translateX = (width - sourceWidth * scale) / 2;
  const translateY = (height - sourceHeight * scale) / 2;

  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.bg }}>
      <div
        style={{
          width: sourceWidth,
          height: sourceHeight,
          transform: `translate(${translateX}px, ${translateY}px) scale(${scale})`,
          transformOrigin: "top left",
          position: "absolute",
        }}
      >
        {children}
      </div>
    </AbsoluteFill>
  );
};
