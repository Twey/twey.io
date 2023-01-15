--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}
import Control.Monad ((>=>))
import           Hakyll hiding (teaserField, teaserFieldWithSeparator)
import qualified Text.HTML.TagSoup as TS
import qualified Text.HTML.TagSoup.Tree as TST
import qualified Data.Set as Set
import qualified Data.Map as Map
import qualified Data.MultiMap as MultiMap
import           Data.Char (toLower)
import           Data.Maybe (listToMaybe, maybeToList)
import System.FilePath
import Data.List (isSuffixOf)
import Data.Time (toGregorian, defaultTimeLocale, utctDay)
import Data.Time.Format (formatTime)
import Hakyll.Core.Compiler.Internal

type MonthOfYear = Int
type Year = Integer

dirPath :: Identifier -> FilePath
dirPath ident = replaceExtension (toFilePath ident) ""

cleanRoute :: Routes
cleanRoute = customRoute $ \ident -> dirPath ident </> "index.html"

asciiDoctorOptions :: FilePath -> [String]
asciiDoctorOptions out =
  [ "--template-dir", "adoc-templates"
  , "--embedded"
  , "--out-file", "-"
  , "-r", "asciidoctor-diagram"
  , "--attribute", "idprefix="
  , "--attribute", "idseparator=-"
  , "--attribute", "source-highlighter=rouge"
  , "--attribute", "imagesoutdir=_site/" ++ takeDirectory out
  , "--attribute", "icons=font"
  , "-"
  ]

-- ensure all tags are closed — for snippets we might have cut off in
-- the middle
fixNesting :: String -> String
fixNesting = renderTags' . go [] . TS.parseTags
  where
    go ends [] = ends
    go ends (tag@(TS.TagOpen name _) : tags)
      = tag : go (TS.TagClose name : ends) tags
    go ends (tag@(TS.TagClose _) : tags)
      | (emit, keep) <- break (== tag) ends
      = emit ++ tag : go (drop 1 keep) tags
    go ends (tag : tags) = tag : go ends tags

asciiDocCompiler :: Rules (Compiler (Item String))
asciiDocCompiler = do
  match "adoc-templates/*" $ compile getResourceBody
  dep <- makePatternDependency "adoc-templates/*"
  rulesExtraDependencies [dep] . return $ do
    body <- getResourceBody
    Just route <- getUnderlying >>= getRoute
    debugCompiler (show route)
    withItemBody (unixFilter "asciidoctor" (asciiDoctorOptions route)) body

postRoute = foldl composeRoutes idRoute
  [ gsubRoute "^posts/" $ const ""
  , cleanRoute
  ]

draftRoute = foldl composeRoutes idRoute
  [ cleanRoute ]

tagRoute = foldl composeRoutes idRoute
  [ gsubRoute "[^a-zA-Z0-9/]+" $ const "-"
  , gsubRoute "[A-Z]+" $ map toLower
  , cleanRoute
  ]

compilePost :: Item String -> Compiler (Item String)
compilePost = foldl ((>=>)) return
  [ saveSnapshot "rawhtml"
  , loadAndApplyTemplate "templates/post.html" postContext
  , loadAndApplyTemplate "templates/page.html" postContext
  , loadAndApplyTemplate "templates/default.html" postContext
  , compilePage
  ]

compilePage :: Item String -> Compiler (Item String)
compilePage = foldl ((>=>)) return
  [ relativizeUrls
  ]

data Section = Section
  { sectionFragment :: String
  , sectionTitle :: String
  }

-- | Customized TagSoup renderer. The default TagSoup renderer escape CSS
-- within style tags, and doesn't properly minimize.
renderTags' :: [TS.Tag String] -> String
renderTags' = TS.renderTagsOptions TS.RenderOptions
    { TS.optRawTag   = (`elem` ["script", "style"]) . map toLower
    , TS.optMinimize = (`Set.member` minimize) . map toLower
    , TS.optEscape   = id
    }
  where
    -- A list of elements which must be minimized
    minimize = Set.fromList
        [ "area", "br", "col", "embed", "hr", "img", "input", "meta", "link"
        , "param"
        ]

tocField :: String -> Snapshot -> Context String
tocField name snapshot = listFieldWith name sectionContext $ \item -> do
  body <- itemBody <$> loadSnapshot (itemIdentifier item) snapshot
  let tags = TST.universeTree (TST.parseTree body :: [TST.TagTree String])
  return $ do
    TST.TagBranch "section" as cs <- tags
    id <- maybeToList $ lookup "id" as
    title <- maybeToList $ getTitle cs
    [flip itemSetBody item $ Section { sectionFragment = id, sectionTitle = renderTags' title }]
  where
    sectionContext :: Context Section
    sectionContext = field "fragment" (return . sectionFragment . itemBody)
                  <> field "title" (return . sectionTitle . itemBody)
    getTitle xs = TST.flattenTree <$> listToMaybe [ c | TST.TagBranch "h2" _ c <- xs ]

data Header = Header
  { headerTag :: TS.Tag String
  , headerContent :: [TS.Tag String]
  }

cleanUrlField key = field key $ \i -> do
    let ident = itemIdentifier i
        empty' = fail $ "No route url found for item " ++ show ident
    url <- maybe empty' toUrl <$> getRoute ident
    return $ if takeFileName url == "index.html"
      then replaceFileName url ""
      else url

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
  match "static/**" $ do
    route $ gsubRoute "^static/" (const "")
    compile copyFileCompiler

  match "assets/**/*.css" $ do
    route   idRoute
    compile compressCssCompiler

  tags <- buildTags "posts/**" $ fromCapture "tags/*"

  tagsRules tags $ \tag pat -> do
    route tagRoute
    compile $ do
      posts <- loadAllSnapshots pat "rawhtml"
      let ctx = mconcat
            [ constField "title" tag
            , monthsField "months" posts
            , constField "pageClass" "archive"
            , tocField "toc" "rawhtml"
            , pageContext
            ]
      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" ctx
        >>= saveSnapshot "rawhtml"
        >>= loadAndApplyTemplate "templates/page.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

  match "assets/**" $ do
    route   idRoute
    compile copyFileCompiler

  adocCompiler <- asciiDocCompiler
  match "posts/**.adoc" $ do
    route     postRoute
    compile $ adocCompiler >>= compilePost

  match "posts/**.html" $ do
    route     postRoute
    compile $ getResourceBody >>= compilePost

  match "posts/**" $ do
    route     postRoute
    compile $ pandocCompiler >>= compilePost

  match "drafts/**.adoc" $ do
    route     draftRoute
    compile $ adocCompiler >>= compilePost

  match "drafts/**.html" $ do
    route     draftRoute
    compile $ getResourceBody >>= compilePost

  match "drafts/**" $ do
    route     draftRoute
    compile $ pandocCompiler >>= compilePost

  create ["index.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/**"
      let ctx = indexContext posts
      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" ctx
        >>= saveSnapshot "rawhtml"
        >>= loadAndApplyTemplate "templates/index.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

englishDateField :: String -> Context a
englishDateField key = field key $ \i -> do
  time <- getItemUTC defaultTimeLocale $ itemIdentifier i
  let (_, _, day) = toGregorian $ utctDay time
  return $ concat
    [ show day
    , "<sup class=\"ordinal-suffix\">"
    , suffix day
    , "</sup>"
    , " of "
    , formatTime defaultTimeLocale "%B, %Y" time
    ]
  where
    suffix n = case quotRem n 10 of
      (1, _) -> "th"
      (_, 1) -> "st"
      (_, 2) -> "nd"
      (_, 3) -> "rd"
      _      -> "th"

groupByMonth :: (MonadMetadata m, MonadFail m)
  => [Item a] -> m [Item ((Year, MonthOfYear), [Item a])]
groupByMonth items = do
  map mkItem . Map.toDescList . MultiMap.toMap . MultiMap.fromList <$>
    (flip mapM items $ \item -> do
      time <- getItemUTC defaultTimeLocale $ itemIdentifier item
      let (year, month, _) = toGregorian $ utctDay time
      return ((year, month), item))
  where
    mkItem :: ((Year, MonthOfYear), [Item a]) -> Item ((Year, MonthOfYear), [Item a])
    mkItem itemBody@((year, month), posts) = Item
      { itemIdentifier = fromFilePath $ monthName month ++ ", " ++ show year
      , itemBody
      }

monthName :: Int -> String
monthName =
  ([ "January"
   , "February"
   , "March"
   , "April"
   , "May"
   , "June"
   , "July"
   , "August"
   , "September"
   , "October"
   , "November"
   , "December"
   ] !!) . subtract 1

monthContext :: Context ((Year, MonthOfYear), [Item String])
monthContext = englishMonthField <> monthField <> postsField
  where
    englishMonthField :: Context ((Year, MonthOfYear), [Item String])
    englishMonthField = field "englishMonth" $ \Item { itemBody = ((year, month), posts) }
      -> return $ monthName month ++ ", " ++ show year

    monthField :: Context ((Year, MonthOfYear), [Item String])
    monthField = field "month" $ \Item { itemBody = ((year, month), posts) }
      -> return $ map toLower (monthName month) <> "-" <> show year

    postsField :: Context ((Year, MonthOfYear), [Item String])
    postsField = listFieldWith "posts" postContext $
      return . snd . itemBody

monthsField :: String -> [Item String] -> Context a
monthsField name = listField name monthContext . groupByMonth

indexContext :: [Item String] -> Context String
indexContext posts = mconcat
  [ constField "pageClass" "index"
  , constField "title" "twey.io"
  , monthsField "months" posts
  , tocField "toc" "rawhtml"
  , pageContext
  ]

postContext :: Context String
postContext = mconcat
  [ dateField "date" "%F"
  , englishDateField "englishDate"
  , constField "pageClass" "post"
  , tocField "toc" "rawhtml"
  , teaserField "teaser" "rawhtml"
  , pageContext
  ]

pageContext :: Context String
pageContext = cleanUrlField "url" <> defaultContext

teaserField :: String           -- ^ Key to use
            -> Snapshot         -- ^ Snapshot to load
            -> Context String   -- ^ Resulting context
teaserField = teaserFieldWithSeparator "<!--more-->"

teaserFieldWithSeparator :: String           -- ^ Separator to use
                         -> String           -- ^ Key to use
                         -> Snapshot         -- ^ Snapshot to load
                         -> Context String   -- ^ Resulting context
teaserFieldWithSeparator separator key snapshot = field key $ \item -> do
    body <- itemBody <$> loadSnapshot (itemIdentifier item) snapshot
    case needlePrefix separator body of
        Nothing -> fail $
            "Hakyll.Web.Template.Context: no teaser defined for " ++
            show (itemIdentifier item)
        Just t -> return $ demoteHeadersBy 2 $ fixNesting t
