import { ImageResponse } from "next/og";

export const size = { width: 32, height: 32 };
export const contentType = "image/png";

export default function Icon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%", height: "100%",
          background: "#2F7D4A", color: "#fff",
          fontSize: 18, fontWeight: 800, letterSpacing: "-0.06em",
          display: "flex", alignItems: "center", justifyContent: "center",
          borderRadius: 8,
        }}
      >
        NV
      </div>
    ),
    size,
  );
}
