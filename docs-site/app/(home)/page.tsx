import Link from 'next/link';

const INSTALL = 'curl -fsSL https://raw.githubusercontent.com/dividendsolo/omarchy4mac/main/install.sh | bash';

export default function HomePage() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-14">
      <div className="flex flex-col gap-3">
        <h1 className="text-3xl font-semibold">omarchy4mac</h1>
        <p className="text-fd-muted-foreground text-lg">
          Omarchy 4, for the Mac. AeroSpace tiles the windows, SketchyBar takes
          the bar, and one script recolours the terminal, the editor, the bar
          and the wallpaper at once.
        </p>
      </div>

      <Link
        href="/docs"
        className="bg-fd-primary text-fd-primary-foreground inline-flex min-h-11 items-center justify-center self-start rounded-lg px-5 font-medium max-sm:self-stretch"
      >
        Read the docs
      </Link>

      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src="/omarchy4mac-desktop.webp"
        alt="The omarchy4mac desktop: Omarchy's bar across the top with five workspaces, a clock, the weather and the gruvbox theme, and a Ghostty terminal below it"
        width={1920}
        height={1080}
        className="border-fd-border w-full rounded-lg border"
      />

      <div className="flex flex-col gap-2">
        <p>Install it with one command. The same command updates it later.</p>
        <pre className="bg-fd-card border-fd-border overflow-x-auto rounded-lg border p-3 text-xs whitespace-pre-wrap break-all sm:text-sm">
          <code>{INSTALL}</code>
        </pre>
      </div>

      <p className="text-fd-muted-foreground">
        It installs Homebrew if needed, links the configs, hides the Dock and
        the menu bar, pulls every Omarchy theme, and asks for one permission
        macOS will not hand out by itself.
      </p>
    </main>
  );
}
