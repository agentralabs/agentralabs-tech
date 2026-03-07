import { Composition } from "remotion";
import { AgentralabsAd } from "./AgentralabsAd";
import {
  AgentralabsAdLinkedIn,
  AgentralabsAdInstagramSquare,
  AgentralabsAdInstagramReels,
  AgentralabsAdX,
} from "./AgentralabsAdWrapped";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* Original 16:9 landscape */}
      <Composition
        id="AgentralabsAd"
        component={AgentralabsAd}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
      />

      {/* LinkedIn — 1920x1080 (16:9 landscape) */}
      <Composition
        id="LinkedIn"
        component={AgentralabsAdLinkedIn}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
      />

      {/* Instagram Feed — 1080x1080 (1:1 square) */}
      <Composition
        id="InstagramFeed"
        component={AgentralabsAdInstagramSquare}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
      />

      {/* Instagram Reels / Stories — 1080x1920 (9:16 vertical) */}
      <Composition
        id="InstagramReels"
        component={AgentralabsAdInstagramReels}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1920}
      />

      {/* X / Twitter — 1280x720 (16:9 landscape) */}
      <Composition
        id="X-Twitter"
        component={AgentralabsAdX}
        durationInFrames={900}
        fps={30}
        width={1280}
        height={720}
      />
    </>
  );
};
