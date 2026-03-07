import React from "react";
import { Sequence, useCurrentFrame, useVideoConfig } from "remotion";
import { SceneIntro } from "./components/SceneIntro";
import { SceneProblem } from "./components/SceneProblem";
import { SceneSolution } from "./components/SceneSolution";
import { SceneSisters } from "./components/SceneSisters";
import { SceneFeatures } from "./components/SceneFeatures";
import { SceneCTA } from "./components/SceneCTA";
import { COLORS } from "./styles";

/**
 * AGENTRA LABS — Advertising Video
 *
 * Timeline (30fps, 900 frames = 30 seconds):
 *   0-120   Scene 1: Brand intro — "AGENTRA LABS" glitch reveal
 * 120-240   Scene 2: Problem — "Your AI forgets you exist."
 * 240-390   Scene 3: Solution — "Ours remembers for 20 years." + tagline
 * 390-600   Scene 4: Seven Sisters showcase
 * 600-750   Scene 5: Features — key differentiators
 * 750-900   Scene 6: CTA — open source, URL, GitHub
 */
export const AgentralabsAd: React.FC = () => {
  return (
    <div
      style={{
        backgroundColor: COLORS.bg,
        width: "100%",
        height: "100%",
        fontFamily: "'JetBrains Mono', 'Courier New', monospace",
      }}
    >
      <Sequence from={0} durationInFrames={120} name="Intro">
        <SceneIntro />
      </Sequence>

      <Sequence from={120} durationInFrames={120} name="Problem">
        <SceneProblem />
      </Sequence>

      <Sequence from={240} durationInFrames={150} name="Solution">
        <SceneSolution />
      </Sequence>

      <Sequence from={390} durationInFrames={210} name="Seven Sisters">
        <SceneSisters />
      </Sequence>

      <Sequence from={600} durationInFrames={150} name="Features">
        <SceneFeatures />
      </Sequence>

      <Sequence from={750} durationInFrames={150} name="CTA">
        <SceneCTA />
      </Sequence>
    </div>
  );
};
