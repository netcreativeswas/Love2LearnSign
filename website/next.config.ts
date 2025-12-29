import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async redirects() {
    return [
      {
        source: "/login",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
      {
        source: "/login/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
      {
        source: "/log-in",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
      {
        source: "/log-in/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
      {
        source: "/signin",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
      {
        source: "/signin/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
