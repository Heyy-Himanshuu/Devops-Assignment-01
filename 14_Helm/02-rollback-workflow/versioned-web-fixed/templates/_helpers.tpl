{{/* The page content. Kept in one place so its hash and the ConfigMap can never disagree. */}}
{{- define "versioned-web.page" -}}
<h1 style="color:{{ .Values.release.color }}">versioned-web {{ .Values.release.version }}</h1>
<p>{{ .Values.release.message }}</p>
<!-- helm revision {{ .Release.Revision }} -->
{{- end }}

{{/*
ConfigMap name carries a hash of its content, so every revision gets its own immutable ConfigMap.
Pods of the previous ReplicaSet keep mounting the previous one, so a failed upgrade can no
longer change what the healthy Pods serve.
*/}}
{{- define "versioned-web.pageName" -}}
{{ .Release.Name }}-page-{{ include "versioned-web.page" . | sha256sum | trunc 8 }}
{{- end }}
