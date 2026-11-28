/** Durable settings namespace for product-wide GUI onboarding facts. */
export const WELCOME_NOTICE_SETTINGS_NAMESPACE = 'ui-onboarding'

/** Field storing the last welcome notice version the user acknowledged. */
export const WELCOME_NOTICE_ACK_FIELD = 'welcomeNoticeVersion'

/**
 * Bump only when the notice changes materially and every user should see it
 * again. The acknowledgement is compared for exact equality.
 */
export const WELCOME_NOTICE_VERSION = '2026-11-28.1'

/** OhamLab Harness welcome experience in both supported GUI locales. */
export const WELCOME_NOTICE_COPY = {
  zh: {
    title: '欢迎使用 OhamLab Harness',
    body: '欢迎来到 OhamLab Harness，一个开放、灵活且可扩展的智能体平台，旨在让人工智能更加易用、强大和个性化。\n\n通过多模型支持、可扩展插件、可复用技能和智能自动化，OhamLab Harness 让您能够自由构建、定制和扩展属于自己的 AI 工作空间，而不受单一模型或服务提供商的限制。\n\n我们相信开放创新、社区协作和持续进步的力量。无论您是开发者、创作者、研究人员，还是 AI 探索者，都欢迎您与我们一起探索智能的无限可能。\n\n自由构建，智能探索，无限创新。\n\n欢迎加入 OhamLab 生态系统。',
    continueLabel: '开始探索',
  },
  en: {
    title: 'Welcome to OhamLab Harness',
    body: 'Welcome to OhamLab Harness — an open, flexible, and extensible AI agent platform designed to make artificial intelligence more accessible, powerful, and personal.\n\nWith multi-model support, extensible plugins, reusable skills, and intelligent automation, OhamLab Harness empowers you to build, customize, and evolve your own AI workspace without being tied to a single model or provider.\n\nWe believe in open innovation, community collaboration, and continuous improvement. Whether you are a developer, creator, researcher, or AI enthusiast, we invite you to explore new possibilities and shape the future of intelligent agents with us.\n\nBuild freely. Think intelligently. Create without limits.\n\nWelcome to the OhamLab ecosystem.',
    continueLabel: 'Get Started',
  },
} as const
