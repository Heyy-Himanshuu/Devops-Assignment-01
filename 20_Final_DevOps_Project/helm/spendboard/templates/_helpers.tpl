{{- define "spendboard.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}{{ .Release.Name | trunc 50 }}{{- else -}}{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 50 }}{{- end -}}
{{- end -}}

{{- define "spendboard.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "spendboard.selector" -}}
app.kubernetes.io/name: {{ .root.Chart.Name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "spendboard.tag" -}}
{{- required "image.tag is required (use the git SHA the pipeline pushed)" .Values.image.tag -}}
{{- end -}}

{{- define "spendboard.podSecurity" -}}
securityContext:
  allowPrivilegeEscalation: false
  capabilities: { drop: ["ALL"] }
{{- end -}}
