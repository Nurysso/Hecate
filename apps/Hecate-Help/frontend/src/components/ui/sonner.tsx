import {
  CircleCheckIcon,
  InfoIcon,
  Loader2Icon,
  OctagonXIcon,
  TriangleAlertIcon,
} from "lucide-react"
import { Toaster as Sonner, type ToasterProps } from "sonner"
import { useState, useEffect } from "react"

const Toaster = ({ theme: propTheme, ...props }: ToasterProps) => {
  const [theme, setTheme] = useState<"light" | "dark" | "system">("system")

  // Auto-detect system theme
  useEffect(() => {
    if (propTheme) {
      setTheme(propTheme)
    } else {
      const dark = window.matchMedia("(prefers-color-scheme: dark)").matches
      setTheme(dark ? "dark" : "light")
    }
  }, [propTheme])

  return (
    <Sonner
      theme={theme}
      className="toaster group"
      icons={{
        success: <CircleCheckIcon className="size-4" />,
        info: <InfoIcon className="size-4" />,
        warning: <TriangleAlertIcon className="size-4" />,
        error: <OctagonXIcon className="size-4" />,
        loading: <Loader2Icon className="size-4 animate-spin" />,
      }}
      style={
        {
          "--normal-bg": "var(--popover)",
          "--normal-text": "var(--popover-foreground)",
          "--normal-border": "var(--border)",
          "--border-radius": "var(--radius)",
        } as React.CSSProperties
      }
      {...props}
    />
  )
}

export { Toaster }
