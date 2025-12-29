import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async redirects() {
    return [
      {
        source: "/login",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/login/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/log-in",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/log-in/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/signin",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/signin/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
