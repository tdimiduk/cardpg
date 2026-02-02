module Frontend.Style.Atomic where

import Data.Text (Text)
import Web.Atomic
import Web.Atomic.CSS

import Web.Atomic.Types (Rule)

-- | The collection of all atomic styles we want to generate.
-- We use this to generate the CSS file.
allStyles :: CSS [Rule]
allStyles =
  mconcat
    [ -- Layout
      atom "flex" "display" "flex"
    , atom "flex-row" "flex-direction" "row"
    , atom "flex-col" "flex-direction" "column"
    , atom "items-center" "align-items" "center"
    , atom "items-end" "align-items" "end"
    , atom "justify-center" "justify-content" "center"
    , atom "justify-between" "justify-content" "space-between"
    , atom "grow" "flex-grow" "1"
    , atom "absolute" "position" "absolute"
    , atom "relative" "position" "relative"
    , atom "hidden" "display" "none"
    , atom "overflow-hidden" "overflow" "hidden"
    , atom "z-10" "z-index" "10"
    , atom "z-20" "z-index" "20"
    , atom "z-30" "z-index" "30"
    , atom "z-40" "z-index" "40"
    , atom "cursor-pointer" "cursor" "pointer"
    , atom "cursor-not-allowed" "cursor" "not-allowed"
    , atom "pointer-events-none" "pointer-events" "none"
    , atom "pointer-events-auto" "pointer-events" "auto"
    , atom {- dummy -} "group" "content" "\"\""
    , atom "inline-block" "display" "inline-block"
    , atom "align-text-bottom" "vertical-align" "text-bottom"
    , -- Sizes
      atom "w-full" "width" "100%"
    , atom "h-full" "height" "100%"
    , atom "w-fit" "width" "fit-content"
    , atom "w-4" "width" "1rem"
    , atom "h-4" "height" "1rem"
    , atom "w-10" "width" "2.5rem"
    , atom "h-10" "height" "2.5rem"
    , atom "w-40" "width" "10rem"
    , -- Explicit mm sizes
      atom "w-[63mm]" "width" "63mm"
    , atom "h-[88mm]" "height" "88mm"
    , atom "w-[8mm]" "width" "8mm"
    , atom "h-[8mm]" "height" "8mm"
    , atom "p-[2.5mm]" "padding" "2.5mm"
    , atom "p-[2mm]" "padding" "2mm"
    , atom "mb-[2mm]" "margin-bottom" "2mm"
    , atom "top-[2mm]" "top" "2mm"
    , atom "right-[2mm]" "right" "2mm"
    , atom "rounded-[3mm]" "border-radius" "3mm"
    , atom "rounded-[2mm]" "border-radius" "2mm"
    , atom "rounded-[1mm]" "border-radius" "1mm"
    , atom "gap-[4mm]" "gap" "4mm"
    , -- Spacing
      atom "p-1" "padding" "0.25rem"
    , atom "pb-1" "padding-bottom" "0.25rem"
    , atom "pr-1" "padding-right" "0.25rem"
    , atom "gap-0" "gap" "0"
    , atom "gap-1" "gap" "0.25rem"
    , atom "gap-4" "gap" "1rem"
    , atom "bottom-0" "bottom" "0"
    , atom "left-0" "left" "0"
    , atom "right-0" "right" "0"
    , atom "inset-0" "inset" "0"
    , -- Colors (Slate approximation)
      atom "bg-slate-900" "background-color" "#0f172a"
    , atom "bg-slate-800" "background-color" "#1e293b"
    , atom "bg-slate-700" "background-color" "#334155"
    , atom "bg-slate-600" "background-color" "#475569"
    , atom "bg-gray-300" "background-color" "#d1d5db"
    , atom "bg-white" "background-color" "white"
    , atom "bg-transparent" "background-color" "transparent"
    , atom "text-slate-100" "color" "#f1f5f9"
    , atom "text-slate-200" "color" "#e2e8f0"
    , atom "text-slate-300" "color" "#cbd5e1"
    , atom "text-black" "color" "black"
    , atom "text-red-500" "color" "#ef4444"
    , atom "text-yellow-400" "color" "#facc15"
    , atom "text-blue-500" "color" "#3b82f6"
    , atom "border-slate-600" "border-color" "#475569"
    , atom "border-slate-700" "border-color" "#334155"
    , atom "border-black" "border-color" "black"
    , atom "border-transparent" "border-color" "transparent"
    , -- Borders
      atom "border" "border-width" "1px"
    , atom "border-0" "border-width" "0px"
    , atom "border-2" "border-width" "2px"
    , atom "rounded" "border-radius" "0.25rem"
    , atom "rounded-none" "border-radius" "0"
    , -- Typography
      atom "font-bold" "font-weight" "700"
    , atom "text-sm" "font-size" "0.875rem"
    , atom "text-xs" "font-size" "0.75rem"
    , atom "text-xl" "font-size" "1.25rem"
    , atom "leading-tight" "line-height" "1.25"
    , atom "uppercase" "text-transform" "uppercase"
    , atom "tracking-wider" "letter-spacing" "0.05em"
    , atom "whitespace-nowrap" "white-space" "nowrap"
    , atom "truncate" "text-overflow" "ellipsis"
    , -- Effects
      atom "shadow-xl" "box-shadow" "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)"
    , atom "shadow-lg" "box-shadow" "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)"
    , atom "grayscale" "filter" "grayscale(100%)"
    , atom "opacity-75" "opacity" "0.75"
    , -- Custom Open Props examples
      atom "text-blue-5" "color" "var(--blue-5)"
    , atom "p-3" "padding" "var(--size-3)"
    , atom "font-size-1" "font-size" "var(--font-size-1)"
    ]

-- | Helper to define a custom atomic class
atom :: Text -> Text -> String -> CSS [Rule]
atom name prop val = utility (ClassName name) [Property prop :. Style val] mempty
